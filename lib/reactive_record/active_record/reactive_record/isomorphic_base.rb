require 'json'

module ReactiveRecord

  class Base

    include React::IsomorphicHelpers

    before_first_mount do |context|
      if RUBY_ENGINE != 'opal'
        @server_data_cache = ReactiveRecord::ServerDataCache.new(context.controller.acting_user, {})
      else
        @public_columns_hash = get_public_columns_hash
        define_attribute_methods
        @outer_scopes = Set.new
        @fetch_scheduled = nil
        initialize_lookup_tables
        if on_opal_client?
          @pending_fetches = []
          @pending_records = []
          #@current_fetch_id = nil
          unless `typeof window.ReactiveRecordInitialData === 'undefined'`
            log(["Reactive record prerendered data being loaded: %o", `window.ReactiveRecordInitialData`])
            JSON.from_object(`window.ReactiveRecordInitialData`).each do |hash|
              load_from_json hash
            end
          end
        end
      end
    end

    def self.deprecation_warning(model, message)
      @deprecation_messages ||= []
      message = "Warning: Deprecated feature used in #{model}. #{message}"
      unless @deprecation_messages.include? message
        @deprecation_messages << message
        log message, :warning
      end
    end

    def deprecation_warning(message)
      self.class.deprecation_warning(model, message)
    end

    def records
      self.class.instance_variable_get(:@records)
    end

    # Prerendering db access (returns nil if on client):
    # at end of prerendering dumps all accessed records in the footer

    isomorphic_method(:fetch_from_db) do |f, vector|
      # vector must end with either "*all", or be a simple attribute
      f.send_to_server [vector.shift.name, *vector] if RUBY_ENGINE == 'opal'
      f.when_on_server { @server_data_cache[*vector] }
    end

    isomorphic_method(:find_in_db) do |f, klass, attrs|
      f.send_to_server klass.name, attrs if RUBY_ENGINE == 'opal'
      f.when_on_server { @server_data_cache[klass, ['find_by', attrs], 'id'] }
    end

    class << self
      attr_reader :public_columns_hash
    end

    def self.define_attribute_methods
      public_columns_hash.keys.each do |model|
        Object.const_get(model).define_attribute_methods rescue nil
      end
    end

    isomorphic_method(:get_public_columns_hash) do |f|
      f.when_on_client { JSON.parse(`JSON.stringify(window.ReactiveRecordPublicColumnsHash)`) }
      f.send_to_server
      f.when_on_server { ActiveRecord::Base.public_columns_hash }
    end

    prerender_footer do
      if @server_data_cache
        json = @server_data_cache.as_json.to_json  # can this just be to_json?
        @server_data_cache.clear_requests
      else
        json = {}.to_json
      end
      "<script type='text/javascript'>\n"+
        "if (typeof window.ReactiveRecordPublicColumnsHash === 'undefined') { \n" +
        "  window.ReactiveRecordPublicColumnsHash = #{ActiveRecord::Base.public_columns_hash_as_json}}\n" +
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
      DummyValue.new(record && record.get_columns_info_for_vector(vector))
    end

    def get_columns_info_for_vector(vector)
      method_name = vector.last
      method_name = method_name.first if method_name.is_a? Array
      model.columns_hash[method_name] || model.server_methods[method_name]
    end


    class << self

      attr_reader :pending_fetches
      attr_reader :current_fetch_id

    end

    def self.schedule_fetch
      React::State.set_state(WhileLoading, :quiet, false) # moved from while loading module see loading! method
      return if @fetch_scheduled
      @current_fetch_id = Time.now
      @fetch_scheduled = after(0) do
        # Skip the fetch if there are no pending_fetches. This would never normally happen
        # but during testing we might reset the context while there are pending fetches
        next unless @pending_fetches.count > 0
        saved_current_fetch_id = @current_fetch_id
        saved_pending_fetches = @pending_fetches.uniq
        models, associations = gather_records(@pending_records, false, nil)
        log(["Server Fetching: %o", saved_pending_fetches.to_n])
        start_time = `Date.now()`
        Operations::Fetch.run(models: models, associations: associations, pending_fetches: saved_pending_fetches)
        .then do |response|
          begin
            fetch_time = `Date.now()`
            log("       Fetched in:   #{`(fetch_time - start_time)/ 1000`}s")
            timer = after(0) do
              log("       Processed in: #{`(Date.now() - fetch_time) / 1000`}s")
              log(['       Returned: %o', response.to_n])
            end
            begin
              ReactiveRecord::Base.load_from_json(response)
            rescue Exception => e
              `clearTimeout(#{timer})`
              log("Unexpected exception raised while loading json from server: #{e}", :error)
            end
            ReactiveRecord.run_blocks_to_load saved_current_fetch_id
          ensure
            ReactiveRecord::WhileLoading.loaded_at saved_current_fetch_id
            ReactiveRecord::WhileLoading.quiet! if @pending_fetches.empty?
          end
        end
        .fail do |response|
          log("Fetch failed", :error)
          begin
            ReactiveRecord.run_blocks_to_load(saved_current_fetch_id, response)
          ensure
            ReactiveRecord::WhileLoading.quiet! if @pending_fetches.empty?
          end
        end
        @pending_fetches = []
        @pending_records = []
        @fetch_scheduled = nil
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
          output_attributes = {record.model.primary_key => record.id.loading? ? nil : record.id}
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

      def save_or_validate(save, validate, force, &block)
        if data_loading?
          sync!
        elsif force || changed?
          HyperMesh.load do
            ReactiveRecord.loads_pending! unless self.class.pending_fetches.empty?
          end.then { send_save_to_server(save, validate, force, &block) }
          #save_to_server(validate, force, &block)
        else
          promise = Promise.new
          yield true, nil, [] if block
          promise.resolve({success: true})
          promise
        end
      end

      def send_save_to_server(save, validate, force, &block)
        models, associations, backing_records = self.class.gather_records([self], force, self)

        begin
          backing_records.each { |id, record| record.saving! } if save

          promise = Promise.new
          Operations::Save.run(models: models, associations: associations, save: save, validate: validate)
          .then do |response|
            begin
              response[:models] = response[:saved_models].collect do |item|
                backing_records[item[0]].ar_instance
              end

              if save
                if response[:success]
                  response[:saved_models].each do |item|
                    Broadcast.to_self backing_records[item[0]].ar_instance, item[2]
                  end
                else
                  log("Reactive Record Save Failed: #{response[:message]}", :error)
                  response[:saved_models].each do | item |
                    log("  Model: #{item[1]}[#{item[0]}]  Attributes: #{item[2]}  Errors: #{item[3]}", :error) if item[3]
                  end
                end
              end

              response[:saved_models].each do | item |
                backing_records[item[0]].sync_unscoped_collection! if save
                backing_records[item[0]].errors! item[3]
              end

              yield response[:success], response[:message], response[:models]  if block
              promise.resolve response  # TODO this could be problematic... there was no .json here, so .... what's to do?

            rescue Exception => e
              # debugger
              log("Exception raised while saving - #{e}", :error)
            ensure
              backing_records.each { |_id, record| record.saved! rescue nil } if save
            end
          end
          promise
        rescue Exception => e
          backing_records.each { |_id, record| record.saved!(true) rescue nil } if save
        end
      rescue Exception => e
        # debugger
        log("Exception raised while saving - #{e}", :error)
        yield false, e.message, [] if block
        promise.resolve({success: false, message: e.message, models: []})
        promise
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
          reactive_records[model_to_save[:id]] = vectors[vector] = record = find_record(model, id, vector, save) # ??? || validate ???
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
          error_messages = []

          #puts "ready to start saving... dont_save_list = #{dont_save_list}"

          saved_models = reactive_records.collect do |reactive_record_id, model|
            #puts "saving rr_id: #{reactive_record_id} model.object_id: #{model.object_id} frozen? <#{model.frozen?}>"
            next unless model
            if !save|| model.frozen? || dont_save_list.include?(model) || model.changed.include?(model.class.primary_key)
              # the above check for changed including the private key happens if you have an aggregate that includes its own id
              # puts "validating frozen model #{model.class.name} #{model} (reactive_record_id = #{reactive_record_id})"
              valid = model.valid?
              # puts "has_errors before = #{has_errors}, validate= #{validate}, !valid= #{!valid}  (validate and !valid) #{validate and !valid}"
              has_errors ||= (validate and !valid)
              # puts "validation complete errors = <#{!valid}>, #{model.errors.messages} has_errors #{has_errors}"
              error_messages << [model, model.errors.messages] unless valid
              [reactive_record_id, model.class.name, model.__hyperloop_secure_attributes(acting_user), (valid ? nil : model.errors.messages)]
            elsif !model.id || model.changed?
              # puts "saving #{model.class.name} #{model} (reactive_record_id = #{reactive_record_id})"
              saved = model.check_permission_with_acting_user(acting_user, new_models.include?(model) ? :create_permitted? : :update_permitted?).save(validate: validate)
              has_errors ||= !saved
              messages = model.errors.messages if (validate and !saved) or (!validate and !model.valid?)
              error_messages << [model, messages] if messages
              # puts "saved complete errors = <#{!saved}>, #{messages} has_errors #{has_errors}"
              [reactive_record_id, model.class.name, model.__hyperloop_secure_attributes(acting_user), messages]
            end
          end.compact

          if has_errors && save
            ::Rails.logger.debug "\033[0;31;1mERROR: HyperModel saving records failed:\033[0;30;21m"
            error_messages.each do |model, messages|
              messages.each do |message|
                ::Rails.logger.debug "\033[0;31;1m\t#{model}: #{message}\033[0;30;21m"
              end
            end
            raise "HyperModel saving records failed!"
          end

          if save || validate

            {success: true, saved_models: saved_models }

          else
            # vectors.each { |vector, model| model.reload unless model.nil? or model.new_record? or model.frozen? }
            vectors

          end

        end

      rescue Exception => e
        #ReactiveRecord::Pry.rescued(e)
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

        #destroy_associations

        promise = Promise.new

        if !data_loading? and (id or vector)
          Operations::Destroy.run(model: ar_instance.model_name, id: id, vector: vector)
          .then do |response|
            Broadcast.to_self ar_instance
            yield response[:success], response[:message] if block
            promise.resolve response
          end
        else
          destroy_associations
          # sync_unscoped_collection! # ? should we do this here was NOT being done before hypermesh integration
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
        #ReactiveRecord::Pry.rescued(e)
        {success: false, record: record, message: e}
      end
    end
  end

end
