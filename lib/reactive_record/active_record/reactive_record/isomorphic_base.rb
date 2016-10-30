require 'json'

module ReactiveRecord

  class Base

    include React::IsomorphicHelpers

    before_first_mount do |context|
      if RUBY_ENGINE != 'opal'
        @server_data_cache = ReactiveRecord::ServerDataCache.new(context.controller.acting_user, {})
      else
        @outer_scopes = Set.new
        @fetch_scheduled = nil
        @records = Hash.new { |hash, key| hash[key] = [] }
        @class_scopes = Hash.new { |hash, key| hash[key] = {} }
        if on_opal_client?
          @pending_fetches = []
          @pending_records = []
          @last_fetch_at = Time.now
          unless `typeof window.ReactiveRecordInitialData === 'undefined'`
            log(["Reactive record prerendered data being loaded: %o", `window.ReactiveRecordInitialData`])
            JSON.from_object(`window.ReactiveRecordInitialData`).each do |hash|
              load_from_json hash
            end
          end
        end
      end
    end

    def records
      self.class.instance_variable_get(:@records)
    end

    # Prerendering db access (returns nil if on client):
    # at end of prerendering dumps all accessed records in the footer

    isomorphic_method(:fetch_from_db) do |f, vector|
      # vector must end with either "*all", or be a simple attribute
      f.send_to_server [vector.shift.name, *vector] if  RUBY_ENGINE == 'opal'
      f.when_on_server { @server_data_cache[*vector] }
    end

    isomorphic_method(:find_in_db) do |f, klass, attribute, value|
      f.send_to_server klass.name, attribute, value if  RUBY_ENGINE == 'opal'
      f.when_on_server { @server_data_cache[klass, ["find_by_#{attribute}", value], :id] }
    end

    prerender_footer do
      if @server_data_cache
        json = @server_data_cache.as_json.to_json  # can this just be to_json?
        @server_data_cache.clear_requests
      else
        json = {}.to_json
      end
      path = ::Rails.application.routes.routes.detect do |route|
        # not sure why the second check is needed.  It happens in the test app
        route.app == ReactiveRecord::Engine or (route.app.respond_to?(:app) and route.app.app == ReactiveRecord::Engine)
      end.path.spec
      "<script type='text/javascript'>\n"+
        "window.ReactiveRecordEnginePath = '#{path}';\n"+
        "if (typeof window.ReactiveRecordInitialData === 'undefined') { window.ReactiveRecordInitialData = [] }\n" +
        "window.ReactiveRecordInitialData.push(#{json})\n"+
      "</script>\n"
    end if RUBY_ENGINE != 'opal'

    # Client side db access (never called during prerendering):

    # Always returns an object of class DummyValue which will act like most standard AR field types
    # Whenever a dummy value is accessed it notify React that there are loads pending so appropriate rerenders
    # will occur when the value is eventually loaded.

    # queue up fetches, and at the end of each rendering cycle fetch the records
    # notify that loads are pending

    def self.load_from_db(record, *vector)
      return nil unless on_opal_client? # this can happen when we are on the server and a nil value is returned for an attribute
      # only called from the client side
      # pushes the value of vector onto the a list of vectors that will be loaded from the server when the next
      # rendering cycle completes.
      # takes care of informing react that there are things to load, and schedules the loader to run
      # Note there is no equivilent to find_in_db, because each vector implicitly does a find.
      raise "attempt to do a find_by_id of nil.  This will return all records, and is not allowed" if vector[1] == ["find_by_id", nil]
      vector = [record.model.model_name, ["new", record.object_id]]+vector[1..-1] if vector[0].nil?
      unless data_loading?
        @pending_fetches << vector
        @pending_records << record if record
        schedule_fetch
      end
      DummyValue.new
    end

    if RUBY_ENGINE == 'opal'
      class ::Object

        def loaded?
          !loading?
        end

        def loading?
          false
        end

        def present?
          !!self
        end

      end

      class DummyValue < NilClass

        def notify
          unless ReactiveRecord::Base.data_loading?
            ReactiveRecord.loads_pending!           #loads
            ReactiveRecord::WhileLoading.loading!   #loads
          end
        end

        def initialize()
          notify
        end

        def method_missing(method, *args, &block)
          if 0.respond_to? method
            notify
            0.send(method, *args, &block)
          elsif "".respond_to? method
            notify
            "".send(method, *args, &block)
          else
            super
          end
        end

        def loading?
          true
        end

        def present?
          false
        end

        def coerce(s)
          [self.send("to_#{s.class.name.downcase}"), s]
        end

        def ==(other_value)
          other_value.object_id == self.object_id
        end

        def zero?
          false
        end

        def to_s
          notify
          ""
        end

        def to_f
          notify
          0.0
        end

        def to_i
          notify
          0
        end

        def to_numeric
          notify
          0
        end

        def to_number
          notify
          0
        end

        def to_date
          notify
          "2001-01-01T00:00:00.000-00:00".to_date
        end

        def acts_as_string?
          true
        end

        def try(*args, &b)
          if args.empty? && block_given?
            yield self
          else
            send(*args, &b)
          end
        rescue
          nil
        end

      end
    end

    class << self

      attr_reader :pending_fetches
      attr_reader :last_fetch_at

    end

    def self.schedule_fetch
      @fetch_scheduled ||= after(0) do
        if @pending_fetches.count > 0  # during testing we might reset the context while there are pending fetches otherwise this would never normally happen
          last_fetch_at = @last_fetch_at
          @last_fetch_at = Time.now
          pending_fetches = @pending_fetches.uniq
          models, associations = gather_records(@pending_records, false, nil)
          log(["Server Fetching: %o", pending_fetches.to_n])
          start_time = Time.now
          HTTP.post(`window.ReactiveRecordEnginePath`,
            payload: {
              json: {
                models:          models,
                associations:    associations,
                pending_fetches: pending_fetches
              }.to_json
            }
          ).then do |response|
            fetch_time = Time.now
            log("       Fetched in:   #{(fetch_time-start_time).to_i}s")
            begin
              ReactiveRecord::Base.load_from_json(response.json)
            rescue Exception => e
              log("Unexpected exception raised while loading json from server: #{e}", :error)
            end
            log("       Processed in: #{(Time.now-fetch_time).to_i}s")
            log(["       Returned: %o", response.json.to_n])
            ReactiveRecord.run_blocks_to_load last_fetch_at
            ReactiveRecord::WhileLoading.loaded_at last_fetch_at
            ReactiveRecord::WhileLoading.quiet! if @pending_fetches.empty?
          end.fail do |response|
            log("Fetch failed", :error)
            ReactiveRecord.run_blocks_to_load(last_fetch_at, response.body)
          end
          @pending_fetches = []
          @pending_records = []
          @fetch_scheduled = nil
        end
      end
    end

    def self.get_type_hash(record)
      {record.class.inheritance_column => record[record.class.inheritance_column]}
    end

    if RUBY_ENGINE == 'opal'

      def self.gather_records(records_to_process, force, record_being_saved)
        # we want to pass not just the model data to save, but also enough information so that on return from the server
        # we can update the models on the client

        # input
        # list of records to process, will grow as we chase associations
        # outputs
        models = [] # the actual data to save {id: record.object_id, model: record.model.model_name, attributes: changed_attributes}
        associations = [] # {parent_id: record.object_id, attribute: attribute, child_id: assoc_record.object_id}

        # used to keep track of records that have been processed for effeciency
        # for quick lookup of records that have been or will be processed [record.object_id] => record
        records_to_process = records_to_process.uniq
        backing_records = Hash[*records_to_process.collect { |record| [record.object_id, record] }.flatten(1)]

        add_new_association = lambda do |record, attribute, assoc_record|
          unless backing_records[assoc_record.object_id]
            records_to_process << assoc_record
            backing_records[assoc_record.object_id] = assoc_record
          end
          associations << {parent_id: record.object_id, attribute: attribute, child_id: assoc_record.object_id}
        end

        record_index = 0
        while(record_index < records_to_process.count)
          record = records_to_process[record_index]
          if record.id.loading? and record_being_saved
            raise "Attempt to save a model while it or an associated model is still loading: model being saved: #{record_being_saved.model}:#{record_being_saved.id}#{', associated model: '+record.model.to_s if record != record_being_saved}"
          end
          output_attributes = {record.model.primary_key => record.id}
          vector = record.vector || [record.model.model_name, ["new", record.object_id]]
          models << {id: record.object_id, model: record.model.model_name, attributes: output_attributes, vector: vector}
          record.attributes.each do |attribute, value|
            if association = record.model.reflect_on_association(attribute)
              if association.collection?
                # following line changed from .all to .collection on 10/28
                [*value.collection, *value.unsaved_children].each do |assoc|
                  add_new_association.call(record, attribute, assoc.backing_record) if assoc.changed?(association.inverse_of) or assoc.new?
                end
              elsif record.new? || record.changed?(attribute) || (record == record_being_saved && force)
                if value.nil?
                  output_attributes[attribute] = nil
                else
                  add_new_association.call record, attribute, value.backing_record
                end
              end
            elsif aggregation = record.model.reflect_on_aggregation(attribute) and (aggregation.klass < ActiveRecord::Base)
              add_new_association.call record, attribute, value.backing_record unless value.nil?
            elsif aggregation
              new_value = aggregation.serialize(value)
              output_attributes[attribute] = new_value if record.changed?(attribute) or new_value != aggregation.serialize(record.synced_attributes[attribute])
            elsif record.new? or record.changed?(attribute)
              output_attributes[attribute] = value
            end
          end if record.new? || record.changed? || (record == record_being_saved && force)
          record_index += 1
        end
        [models, associations, backing_records]
      end

      def save(validate, force, &block)

        if data_loading?

          sync!

        elsif force or changed?

          begin

            models, associations, backing_records = self.class.gather_records([self], force, self)

            backing_records.each { |id, record| record.saving! }

            promise = Promise.new

            HTTP.post(`window.ReactiveRecordEnginePath`+"/save",
              payload: {
                json: {
                  models:       models,
                  associations: associations,
                  validate:     validate
                }.to_json
              }
            ).then do |response|
              begin
                response.json[:models] = response.json[:saved_models].collect do |item|
                  backing_records[item[0]].ar_instance
                end

                if response.json[:success]
                  response.json[:saved_models].each { | item | backing_records[item[0]].sync!(item[2]) }
                else
                  log("Reactive Record Save Failed: #{response.json[:message]}", :error)
                  response.json[:saved_models].each do | item |
                    log("  Model: #{item[1]}[#{item[0]}]  Attributes: #{item[2]}  Errors: #{item[3]}", :error) if item[3]
                  end
                end

                response.json[:saved_models].each do | item |
                  backing_records[item[0]].sync_unscoped_collection!
                  backing_records[item[0]].errors! item[3]
                end

                yield response.json[:success], response.json[:message], response.json[:models]  if block
                promise.resolve response.json

                backing_records.each { |id, record| record.saved! }

              rescue Exception => e
                log("Exception raised while saving - #{e}", :error)
              end
            end
            promise
          rescue Exception => e
            log("Exception raised while saving - #{e}", :error)
            yield false, e.message, [] if block
            promise.resolve({success: false, message: e.message, models: []})
            promise
          end
        else
          promise = Promise.new
          yield true, nil, [] if block
          promise.resolve({success: true})
          promise
        end
      end

    else

      def self.find_record(model, id, vector, save)
        if !save
          found = vector[1..-1].inject(vector[0]) do |object, method|
            if object.nil? # happens if you try to do an all on empty scope followed by more scopes
              object
            elsif method.is_a? Array
              if method[0] == 'new'
                object.new
              else
                object.send(*method)
              end
            elsif method.is_a? String and method[0] == '*'
              object[method.gsub(/^\*/,'').to_i]
            else
              object.send(method)
            end
          end
          if id and (found.nil? or !(found.class <= model) or (found.id and found.id.to_s != id.to_s))
            raise "Inconsistent data sent to server - #{model.name}.find(#{id}) != [#{vector}]"
          end
          found
        elsif id
          model.find(id)
        else
          model.new
        end
      end


      def self.is_enum?(record, key)
        record.class.respond_to?(:defined_enums) && record.class.defined_enums[key]
      end

      def self.save_records(models, associations, acting_user, validate, save)
        reactive_records = {}
        vectors = {}
        new_models = []
        saved_models = []
        dont_save_list = []

        models.each do |model_to_save|
          attributes = model_to_save[:attributes]
          model = Object.const_get(model_to_save[:model])
          id = attributes.delete(model.primary_key) if model.respond_to? :primary_key # if we are saving existing model primary key value will be present
          vector = model_to_save[:vector]
          vector = [vector[0].constantize] + vector[1..-1].collect do |method|
            if method.is_a?(Array) and method.first == "find_by_id"
              ["find", method.last]
            else
              method
            end
          end
          reactive_records[model_to_save[:id]] = vectors[vector] = record = find_record(model, id, vector, save)
          if record and record.respond_to?(:id) and record.id
            # we have an already exising activerecord model
            keys = record.attributes.keys
            attributes.each do |key, value|
              if is_enum?(record, key)
                record.send("#{key}=",value)
              elsif keys.include? key
                record[key] = value
              elsif !value.nil? and aggregation = record.class.reflect_on_aggregation(key.to_sym) and !(aggregation.klass < ActiveRecord::Base)
                aggregation.mapping.each_with_index do |pair, i|
                  record[pair.first] = value[i]
                end
              elsif record.respond_to? "#{key}="
                record.send("#{key}=",value)
              else
                # TODO once reading schema.rb on client is implemented throw an error here
              end
            end
          elsif record
            # either the model is new, or its not even an active record model
            dont_save_list << record unless save
            keys = record.attributes.keys
            attributes.each do |key, value|
              if is_enum?(record, key)
                record.send("#{key}=",value)
              elsif keys.include? key
                record[key] = value
              elsif !value.nil? and aggregation = record.class.reflect_on_aggregation(key) and !(aggregation.klass < ActiveRecord::Base)
                aggregation.mapping.each_with_index do |pair, i|
                  record[pair.first] = value[i]
                end
              elsif key.to_s != "id" and record.respond_to?("#{key}=")  # server side methods can get included and we won't be able to write them...
                # for example if you have a server side method foo, that you "get" on a new record, then later that value will get sent to the server
                # we should track better these server side methods so this does not happen
                record.send("#{key}=",value)
              end
            end
            new_models << record
          end
        end

        #puts "!!!!!!!!!!!!!!attributes updated"
        ActiveRecord::Base.transaction do
          associations.each do |association|
            parent = reactive_records[association[:parent_id]]
            next unless parent
            #parent.instance_variable_set("@reactive_record_#{association[:attribute]}_changed", true) remove this????
            if parent.class.reflect_on_aggregation(association[:attribute].to_sym)
              #puts ">>>>>>AGGREGATE>>>> #{parent.class.name}.send('#{association[:attribute]}=', #{reactive_records[association[:child_id]]})"
              aggregate = reactive_records[association[:child_id]]
              dont_save_list << aggregate
              current_attributes = parent.send(association[:attribute]).attributes
              #puts "current parent attributes = #{current_attributes}"
              new_attributes = aggregate.attributes
              #puts "current child attributes = #{new_attributes}"
              merged_attributes = current_attributes.merge(new_attributes) { |k, current_attr, new_attr| aggregate.send("#{k}_changed?") ? new_attr : current_attr}
              #puts "merged attributes = #{merged_attributes}"
              aggregate.assign_attributes(merged_attributes)
              #puts "aggregate attributes after merge = #{aggregate.attributes}"
              parent.send("#{association[:attribute]}=", aggregate)
              #puts "updated  is frozen? #{aggregate.frozen?}, parent attributes = #{parent.send(association[:attribute]).attributes}"
            elsif parent.class.reflect_on_association(association[:attribute].to_sym).nil?
              raise "Missing association :#{association[:attribute]} for #{parent.class.name}.  Was association defined on opal side only?"
            elsif parent.class.reflect_on_association(association[:attribute].to_sym).collection?
              #puts ">>>>>>>>>> #{parent.class.name}.send('#{association[:attribute]}') << #{reactive_records[association[:child_id]]})"
              dont_save_list.delete(parent)
              if false and parent.new?
                parent.send("#{association[:attribute]}") << reactive_records[association[:child_id]] if parent.new?
                #puts "updated"
              else
                #puts "skipped"
              end
            else
              #puts ">>>>ASSOCIATION>>>> #{parent.class.name}.send('#{association[:attribute]}=', #{reactive_records[association[:child_id]]})"
              parent.send("#{association[:attribute]}=", reactive_records[association[:child_id]])
              dont_save_list.delete(parent)
              #puts "updated"
            end
          end if associations

          #puts "!!!!!!!!!!!!associations updated"

          has_errors = false

          #puts "ready to start saving... dont_save_list = #{dont_save_list}"

          saved_models = reactive_records.collect do |reactive_record_id, model|
            #puts "saving rr_id: #{reactive_record_id} model.object_id: #{model.object_id} frozen? <#{model.frozen?}>"
            if model and (model.frozen? or dont_save_list.include?(model) or model.changed.include?(model.class.primary_key))
              # the above check for changed including the private key happens if you have an aggregate that includes its own id
              #puts "validating frozen model #{model.class.name} #{model} (reactive_record_id = #{reactive_record_id})"
              valid = model.valid?
              #puts "has_errors before = #{has_errors}, validate= #{validate}, !valid= #{!valid}  (validate and !valid) #{validate and !valid}"
              has_errors ||= (validate and !valid)
              #puts "validation complete errors = <#{!valid}>, #{model.errors.messages} has_errors #{has_errors}"
              [reactive_record_id, model.class.name, model.attributes,  (valid ? nil : model.errors.messages)]
            elsif model and (!model.id or model.changed?)
              #puts "saving #{model.class.name} #{model} (reactive_record_id = #{reactive_record_id})"
              saved = model.check_permission_with_acting_user(acting_user, new_models.include?(model) ? :create_permitted? : :update_permitted?).save(validate: validate)
              has_errors ||= !saved
              messages = model.errors.messages if (validate and !saved) or (!validate and !model.valid?)
              #puts "saved complete errors = <#{!saved}>, #{messages} has_errors #{has_errors}"
              [reactive_record_id, model.class.name, model.attributes, messages]
            end
          end.compact

          raise "Could not save all models" if has_errors

          if save

            {success: true, saved_models: saved_models }

          else

            vectors.each { |vector, model| model.reload unless model.nil? or model.new_record? or model.frozen? }
            vectors

          end

        end

      rescue Exception => e
        ReactiveRecord::Pry.rescued(e)
        if save
          {success: false, saved_models: saved_models, message: e}
        else
          {}
        end
      end

    end

    # destroy records

    if RUBY_ENGINE == 'opal'

      def destroy(&block)

        return if @destroyed

        model.reflect_on_all_associations.each do |association|
          if association.collection?
            attributes[association.attribute].replace([]) if attributes[association.attribute]
          else
            @ar_instance.send("#{association.attribute}=", nil)
          end
        end

        promise = Promise.new

        if !data_loading? and (id or vector)
          HTTP.post(`window.ReactiveRecordEnginePath`+"/destroy",
            payload: {
              json: {
                model:  ar_instance.model_name,
                id:     id,
                vector: vector
              }.to_json
            }
          ).then do |response|
            sync_unscoped_collection!
            yield response.json[:success], response.json[:message] if block
            promise.resolve response.json
          end
        else
          yield true, nil if block
          promise.resolve({success: true})
        end

        # DO NOT CLEAR ATTRIBUTES.  Records that are not found, are destroyed, and if they are searched for again, we want to make
        # sure to find them.  We may want to change this, and provide a separate flag called not_found.  In this case you
        # would put these lines here:
        # @attributes = {}
        # sync!
        # and modify server_data_cache so that it does NOT call destroy

        @destroyed = true

        promise
      end

    else

      def self.destroy_record(model, id, vector, acting_user)
        model = Object.const_get(model)
        record = if id
          model.find(id)
        else
          ServerDataCache.new(acting_user, {})[*vector]
        end


        record.check_permission_with_acting_user(acting_user, :destroy_permitted?).destroy
        {success: true, attributes: {}}

      rescue Exception => e
        ReactiveRecord::Pry.rescued(e)
        {success: false, record: record, message: e}
      end
    end
  end

end
