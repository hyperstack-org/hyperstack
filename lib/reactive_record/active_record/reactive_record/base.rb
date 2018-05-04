module ReactiveRecord
  class Base
    include BackingRecordInspector
    include Setters
    include Getters
    extend  LookupTables

    # Its all about lazy loading. This prevents us from grabbing enormous association collections, or large attributes
    # unless they are explicitly requested.

    # During prerendering we get each attribute as its requested and fill it in both on the javascript side, as well as
    # remember that the attribute needs to be part of the download to client.

    # On the client we fill in the record data with empty values (the default value for the attribute,
    # or one element collections) but only as the attribute
    # is requested.  Each request queues up a request to get the real data from the server.

    # The ReactiveRecord class serves two purposes.  First it is the unique data corresponding to the last known state of a
    # database record.  This means All records matching a specific database record are unique.  This is unlike AR but is
    # important both for the lazy loading and also so that when values change react can be informed of the change.

    # Secondly it serves as name space for all the ReactiveRecord specific methods, so every AR Instance has a ReactiveRecord

    # Because there is no point in generating a new ar_instance everytime a search is made we cache the first ar_instance created.
    # Its possible however during loading to create a new ar_instances that will in the end point to the same record.

    # VECTORS... are an important concept.  They are the substitute for a primary key before a record is loaded.
    # Vectors have the form [ModelClass, method_call, method_call, method_call...]

    # Each method call is either a simple method name or an array in the form [method_name, param, param ...]
    # Example [User, [find, 123], todos, active, [due, "1/1/2016"], title]
    # Roughly corresponds to this query: User.find(123).todos.active.due("1/1/2016").select(:title)

    attr_accessor :ar_instance
    attr_accessor :vector
    attr_accessor :model
    attr_accessor :changed_attributes
    attr_accessor :aggregate_owner
    attr_accessor :aggregate_attribute
    attr_accessor :destroyed
    attr_accessor :updated_during
    attr_accessor :synced_attributes
    attr_accessor :virgin
    attr_reader   :attributes

    # While data is being loaded from the server certain internal behaviors need to change
    # for example all record changes are synced as they happen.
    # This is implemented this way so that the ServerDataCache class can use pure active
    # record methods in its implementation

    def self.data_loading?
      @data_loading
    end

    def data_loading?
      self.class.data_loading?
    end

    def self.load_data(&block)
      current_data_loading, @data_loading = [@data_loading, true]
      yield
    ensure
      @data_loading = current_data_loading
    end

    def self.load_from_json(json, target = nil)
      load_data { ServerDataCache.load_from_json(json, target) }
    end

    def self.find(model, attrs)
      # will return the unique record with this attribute-value pair
      # value cannot be an association or aggregation

      # add the inheritance column if this is an STI subclass

      inher_col = model.inheritance_column
      if inher_col && model < model.base_class && !attrs.key?(inher_col)
        attrs = attrs.merge(inher_col => model.model_name)
      end

      model = model.base_class
      primary_key = model.primary_key

      # already have a record with these attribute-value pairs?

      record =
        if (id_to_find = attrs[primary_key])
          lookup_by_id(model, id_to_find)
        else
          @records[model].detect do |r|
            !attrs.detect { |attr, value| r.synced_attributes[attr] != value }
          end
        end

      unless record
        # if not, and then the record may be loaded, but not have this attribute set yet,
        # so find the id of of record with the attribute-value pair, and see if that is loaded.
        # find_in_db returns nil if we are not prerendering which will force us to create a new record
        # because there is no way of knowing the id.
        if !attrs.key?(primary_key) && (id = find_in_db(model, attrs))
          record = lookup_by_id(model, id) # @records[model].detect { |record| record.id == id}
          attrs = attrs.merge primary_key => id
        end
        # if we don't have a record then create one
        # (record = new(model)).vector = [model, [:find_by, attribute => value]] unless record
        record ||= set_vector_lookup(new(model), [model, [:find_by, attrs]])
        # and set the values
        attrs.each { |attr, value| record.sync_attribute(attr, value) }
      end
      # finally initialize and return the ar_instance
      record.set_ar_instance!
    end

    def self.new_from_vector(model, aggregate_owner, *vector)
      # this is the equivilent of find but for associations and aggregations
      # because we are not fetching a specific attribute yet, there is NO communication with the
      # server.  That only happens during find.
      model = model.base_class

      # do we already have a record with this vector?  If so return it, otherwise make a new one.

      # record = @records[model].detect { |record| record.vector == vector }
      record = lookup_by_vector(vector)
      unless record

        record = new model
        set_vector_lookup(record, vector)
      end

      record.set_ar_instance!

      if aggregate_owner
        record.aggregate_owner = aggregate_owner
        record.aggregate_attribute = vector.last
        aggregate_owner.attributes[vector.last] = record.ar_instance
      end

      record.ar_instance
    end

    def initialize(model, hash = {}, ar_instance = nil)
      @model = model
      @ar_instance = ar_instance
      @synced_attributes = {}
      @attributes = {}
      @changed_attributes = []
      @virgin = true
      records[model] << self
      Base.set_object_id_lookup(self)
    end

    def find(*args)
      self.class.find(*args)
    end

    def new_from_vector(*args)
      self.class.new_from_vector(*args)
    end

    def primary_key
      @model.primary_key
    end

    def id
      @attributes[primary_key]
    end

    def id=(value)
      # value can be nil if we are loading an aggregate otherwise check if it already exists
      # if !(value && (existing_record = records[@model].detect { |record| record.attributes[primary_key] == value}))
      if !(value && (existing_record = Base.lookup_by_id(model, value)))
        @attributes[primary_key] = value
        Base.set_id_lookup(self)
      else
        @ar_instance.instance_variable_set(:@backing_record, existing_record)
        existing_record.attributes.merge!(attributes) { |key, v1, v2| v1 }
      end
      value
    end

    def changed?(*args)
      if args.count == 0
        React::State.get_state(self, "!CHANGED!")
        !changed_attributes.empty?
      else
        React::State.get_state(self, args[0])
        changed_attributes.include? args[0]
      end
    end

    def changed_attributes_and_values
      Hash[changed_attributes.collect do |attr|
        [attr, @attributes[attr]] if column_type(attr)
      end.compact]
    end

    def changes
      Hash[changed_attributes.collect do |attr|
        [attr, [@synced_attributes[attr], @attributes[attr]]] if column_type(attr)
      end.compact]
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    # called when we have a newly created record, to initialize
    # any nil collections to empty arrays.  We can do this because
    # if its a brand new record, then any collections that are still
    # nil must not have any children.

    def initialize_collections
      if (!vector || vector.empty?) && id && id != ''
        Base.set_vector_lookup(self, [@model, [:find_by, @model.primary_key => id]])
      end
      Base.load_data do
        @model.reflect_on_all_associations.each do |assoc|
          next if !assoc.collection? || @attributes[assoc.attribute]
          ar_instance.send("#{assoc.attribute}=", [])
        end
      end
    end

    # sync! now will also initialize any nil collections
    def sync!(hash = {}) # does NOT notify (see saved! for notification)
      # hash.each do |attr, value|
      #   @attributes[attr] = convert(attr, value)
      # end
      @synced_attributes = {}
      hash.each { |attr, value| sync_attribute(attr, convert(attr, value)) }
      @changed_attributes = []
      @saving = false
      errors.clear
      # set the vector and clear collections - this only happens when a new record is saved
      initialize_collections if (!vector || vector.empty?) && id && id != ''
      self
    end

    # this keeps the unscoped collection up to date.
    # @destroy_sync and @create_sync prevent multiple insertions
    # to collections that just have a count
    def sync_unscoped_collection!
      if destroyed
        return if @destroy_sync
        @destroy_sync = true
      else
        return if @create_sync
        @create_sync = true
      end
      model.unscoped << ar_instance
      @synced_with_unscoped = !@synced_with_unscoped
    end

    def sync_attribute(attribute, value)

      @synced_attributes[attribute] = @attributes[attribute] = value
      Base.set_id_lookup(self) if attribute == primary_key

      #@synced_attributes[attribute] = value.dup if value.is_a? ReactiveRecord::Collection

      if value.is_a? Collection
        @synced_attributes[attribute] = value.dup_for_sync
      elsif aggregation = model.reflect_on_aggregation(attribute) and (aggregation.klass < ActiveRecord::Base)
        value.backing_record.sync!
      elsif aggregation
        @synced_attributes[attribute] = aggregation.deserialize(aggregation.serialize(value))
      elsif !model.reflect_on_association(attribute)
        @synced_attributes[attribute] = JSON.parse(value.to_json)
      end

      @changed_attributes.delete(attribute)
      value
    end

    # helper so we can tell if model exists.  We need this so we can detect
    # if a record has local changes that are out of sync.
    def self.exists?(model, id)
      Base.lookup_by_id(model, id)
    end

    def revert
      @changed_attributes.dup.each do |attribute|
        @ar_instance.send("#{attribute}=", @synced_attributes[attribute])
        @attributes.delete(attribute) unless @synced_attributes.key?(attribute)
      end
      @changed_attributes = []
      errors.clear
    end

    def saving!
      React::State.set_state(self, self, :saving) unless data_loading?
      @saving = true
    end

    def errors!(hash)
      notify_waiting_for_save
      errors.clear && return unless hash
      hash.each do |attribute, messages|
        messages.each do |message|
          errors.add(attribute, message: message)
        end
      end
    end

    def saved!(save_only = nil) # sets saving to false AND notifies
      notify_waiting_for_save
      return self if save_only
      if errors.empty?
        React::State.set_state(self, self, :saved)
      elsif !data_loading?
        React::State.set_state(self, self, :error)
      end
      self
    end

    def self.when_not_saving(model, &block)
      if @records[model].detect(&:saving?)
        wait_for_save(model, &block)
      else
        yield model
      end
    end

    def notify_waiting_for_save
      @saving = false
      self.class.notify_waiting_for_save(model)
    end

    def self.notify_waiting_for_save(model)
      waiters = waiting_for_save(model)
      return if waiters.empty? || @records[model].detect(&:saving?)
      waiters.each { |waiter| waiter.call model }
      clear_waiting_for_save(model)
    end

    def saving?
      React::State.get_state(self, self)
      @saving
    end

    def new?
      !id && !vector
    end

    def set_ar_instance!
      klass = self.class.infer_type_from_hash(model, @attributes)
      @ar_instance = klass._new_without_sti_type_cast(self) unless @ar_instance.class == klass
      @ar_instance
    end

    class << self
      def infer_type_from_hash(klass, hash)
        klass = klass.base_class
        return klass unless hash
        type = hash[klass.inheritance_column]
        begin
          return Object.const_get(type)
        rescue Exception => e
          message = "Could not subclass #{klass} as #{type}.  Perhaps #{type} class has not been required. Exception: #{e}"
          `console.error(#{message})`
        end unless !type || type == ''
        klass
      end

      attr_reader :outer_scopes

      def default_scope
        @class_scopes[:default_scope]
      end

      def unscoped
        @class_scopes[:unscoped]
      end

      def add_to_outer_scopes(item)
        @outer_scopes << item
      end

      # While evaluating scopes we want to catch any requests
      # to the server.  Once we catch any requests to the server
      # then all the further scopes in that chain will be made
      # at the server.

      class DbRequestMade < RuntimeError; end

      def catch_db_requests(return_val = nil)
        @catch_db_requests = true
        yield
      rescue DbRequestMade => e
        React::IsomorphicHelpers.log "Warning: request for server side data during scope evaluation: #{e.message}", :warning
        return_val
      ensure
        @catch_db_requests = false
      end

      alias pre_synchromesh_load_from_db load_from_db

      def load_from_db(*args)
        raise DbRequestMade, args if @catch_db_requests
        pre_synchromesh_load_from_db(*args)
      end
    end

    def destroy_associations
      @destroyed = false
      model.reflect_on_all_associations.each do |association|
        if association.collection?
          @attributes[association.attribute].replace([]) if @attributes[association.attribute]
        else
          @ar_instance.send("#{association.attribute}=", nil)
        end
      end
      @destroyed = true
    end
  end
end
