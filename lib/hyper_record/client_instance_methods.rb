module HyperRecord
  module ClientInstanceMethods

    def initialize(record_hash = {})
      # initalize internal data structures
      record_hash = {} if record_hash.nil?
      @properties = {}
      @changed_properties = {}
      @relations = {}
      @rest_methods = {}
      @destroyed = false
      # for reactivity, possible @fetch_states:
      # n - not fetched
      # f - fetched
      # i - fetch in progress
      # u - update needed, fetch on next usage
      @fetch_states = {}
      @state_key = "#{self.class.to_s}_#{self.object_id}"
      @observers = Set.new
      @registered_collections = Set.new

      _initialize_from_hash(record_hash)

      # for reactivity
      _register_observer
    end

    def _initialize_from_hash(record_hash)
      reflections.keys.each do |relation|
        if record_hash.has_key?(relation)
          @fetch_states[relation] = 'f' # fetched
          if %i[has_many has_and_belongs_to_many].include?(reflections[relation][:kind])
            if record_hash[relation].nil?
              @relations[relation] = HyperRecord::Collection.new([], self, relation)
            else
              @relations[relation] = self.class._convert_array_to_collection(record_hash[relation], self, relation)
            end
          else
            @relations[relation] = self.class._convert_json_hash_to_record(record_hash[relation])
          end
        else
          unless @fetch_states[collection] == 'f'
            if %i[has_many has_and_belongs_to_many].include?(reflections[relation][:kind])
              @relations[relation] = HyperRecord::Collection.new([], self, relation)
            else
              @relations[relation] = nil
            end
            @fetch_states[relation] = 'n'
          end
        end
        record_hash.delete(relation)
      end

      @properties = record_hash

      # cache in global cache
      self.class._record_cache[@properties[:id].to_s] = self if @properties.has_key?(:id)
    end

    ### reactive api

    def destroy
      promise_destroy
      nil
    end

    def destroyed?
      @destroyed
    end

    def link(other_record)
      _register_observer
      promise_link(other_record).then do
        _notify_observers
      end
      self
    end

    def method_missing(method, arg)
      _register_observer
      if method.end_with?('=')
        @changed_properties[method.chop] = arg
      else
        if @changed_properties.has_key?(method)
          @changed_properties[method]
        else
          @properties[method]
        end
      end
    end

    def reflections
      self.class.reflections
    end

    def reset
      _register_observer
      @changed_properties = {}
    end

    def resource_base_uri
      self.class.resource_base_uri
    end

    def save
      _register_observer
      promise_save.then do
        _notify_observers
      end
      self
    end

    def to_hash
      _register_observer
      res = @properties.dup
      res.merge!(@changed_properties)
      res
    end

    def to_s
      _register_observer
      @properties.to_s
    end

    def unlink(other_record)
      _register_observer
      promise_unlink(other_record).then do
        _notify_observers
      end
      self
    end

    ### promise api

    def promise_destroy
      _local_destroy
      self.class._promise_delete("#{resource_base_uri}/#{@properties[:id]}").then do |response|
        self
      end.fail do |response|
        error_message = "Destroying record #{self} failed!"
        `console.error(error_message)`
        response
      end
    end

    def promise_link(other_record, relation_name = nil)
      called_from_collection = relation_name ? true : false
      relation_name = other_record.class.to_s.underscore.pluralize unless relation_name
      if reflections.has_key?(relation_name)
        @relations[relation_name].push(other_record) if !called_from_collection && @fetch_states[relation_name] == 'f'
      else
        relation_name = other_record.class.to_s.underscore
        raise "No collection for record of type #{other_record.class}" unless reflections.has_key?(relation_name)
        @relations[relation_name].push(other_record) if !called_from_collection && @fetch_states[relation_name] == 'f'
      end
      payload_hash = other_record.to_hash
      self.class._promise_post("#{resource_base_uri}/#{self.id}/relations/#{relation_name}.json", { data: payload_hash }).then do |response|
        other_record.instance_variable_get(:@properties).merge!(response.json[other_record.class.to_s.underscore])
        self
      end.fail do |response|
        error_message = "Linking record #{other_record} to #{self} failed!"
        `console.error(error_message)`
        response
      end
    end

    def promise_save
      payload_hash = @properties.merge(@changed_properties) # copy hash, because we need to delete some keys
      (%i[id created_at updated_at] + reflections.keys).each do |key|
        payload_hash.delete(key)
      end
      if @properties[:id] && ! (@changed_properties.has_key?(:id) && @changed_properties[:id].nil?)
        reset
        self.class._promise_patch("#{resource_base_uri}/#{@properties[:id]}", { data: payload_hash }).then do |response|
          @properties.merge!(response.json[self.class.to_s.underscore])
          self
        end.fail do |response|
          error_message = "Saving record #{self} failed!"
          `console.error(error_message)`
          response
        end
      else
        reset
        self.class._promise_post(resource_base_uri, { data: payload_hash }).then do |response|
          @properties.merge!(response.json[self.class.to_s.underscore])
          self
        end.fail do |response|
          error_message = "Creating record #{self} failed!"
          `console.error(error_message)`
          response
        end
      end
    end

    def promise_unlink(other_record, relation_name = nil)
      called_from_collection = collection_name ? true : false
      relation_name = other_record.class.to_s.underscore.pluralize unless relation_name
      raise "No relation for record of type #{other_record.class}" unless reflections.has_key?(relation_name)
      @relations[relation_name].delete_if { |cr| cr == other_record } if !called_from_collection && @fetch_states[relation_name] == 'f'
      self.class._promise_delete("#{resource_base_uri}/#{@properties[:id]}/relations/#{relation_name}.json?record_id=#{other_record.id}").then do |response|
        self
      end.fail do |response|
        error_message = "Unlinking #{other_record} from #{self} failed!"
        `console.error(error_message)`
        response
      end
    end

    ### internal

    def _local_destroy
      _register_observer
      @destroyed = true
      self.class._record_cache.delete(@properties[:id].to_s)
      @registered_collections.dup.each do |collection|
        collection.delete(self)
      end
      @registered_collections = Set.new
      _notify_observers
    end

    def _notify_observers
      mutate.record_state(`Date.now() + Math.random()`)
      @observers.each do |observer|
        React::State.set_state(observer, @state_key, `Date.now() + Math.random()`)
      end
      @observers = Set.new
      self.class._notify_class_observers
    end

    def _register_collection(collection)
      @registered_collections << collection
    end

    def _register_observer
      observer = React::State.current_observer
      if observer
        React::State.get_state(observer, @state_key)
        @observers << observer # @observers is a set, observers get added only once
      end
    end

    def _unregister_collection(collection)
      @registered_collections.delete(collection)
    end

    def _update_record(data)
      if data.has_key?(:relation)
        if data.has_key?(:cause)
          # this creation of variables for things that could be done in one line
          # are a workaround for Safari, to get it updating correctly
          klass_name = data[:cause][:record_type]
          c_record_class = Object.const_get(klass_name)
          if c_record_class._record_cache.has_key?(data[:cause][:id].to_s)
            c_record = c_record_class.find(data[:cause][:id])
            if data[:cause][:destroyed]
              c_record.instance_variable_set(:@remotely_destroyed, true)
              c_record._local_destroy
            end
            if `Date.parse(#{c_record.updated_at}) >= Date.parse(#{data[:cause][:updated_at]})`
              if @fetch_states[data[:relation]] == 'f'
                if @relations[data[:relation]].include?(c_record)
                  return unless data[:cause][:destroyed]
                end
              end
            end
          end
        end
        @fetch_states[data[:relation]] = 'u'
        send("promise_#{data[:relation]}").then do |collection|
          _notify_observers
        end.fail do |response|
          error_message = "#{self}[#{self.id}].#{data[:relation]} failed to update!"
          `console.error(error_message)`
        end
        return
      end
      if data.has_key?(:rest_method)
        @fetch_states[data[:rest_method]] = 'u'
        if data[:rest_method].include?('_[')
          # rest_method with params
          _notify_observers
        else
          # rest_method without params
          send("promise_#{data[:rest_method]}").then do |result|
            _notify_observers
          end.fail do |response|
            error_message = "#{self}[#{self.id}].#{data[:rest_method]} failed to update!"
            `console.error(error_message)`
          end
        end
        return
      end
      if data[:destroyed]
        return if self.destroyed?
        @remotely_destroyed = true
        _local_destroy
        return
      end
      if @properties[:updated_at] && data[:updated_at]
        return if `Date.parse(#{@properties[:updated_at]}) >= Date.parse(#{data[:updated_at]})`
      end
      self.class._class_fetch_states["record_#{id}"] = 'u'
      self.class._promise_find(@properties[:id], self).then do |record|
        _notify_observers
        self
      end.fail do |response|
        error_message = "#{self} failed to update!"
        `console.error(error_message)`
      end
    end
  end
end
