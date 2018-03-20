module HyperRecord
  module ClientInstanceMethods

    def initialize(record_hash = {})
      # initalize internal data structures
      record_hash = {} if record_hash.nil?
      @properties_hash = {}
      @changed_properties_hash = {}
      @relations = {}
      @rest_methods_hash = {}
      self.class.rest_methods.keys.each { |method| @rest_methods_hash[method] = {} }
      @destroyed = false
      # for reactivity
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
          if reflections[relation][:kind] == :has_many
            if record_hash[relation].nil?
              @relations[relation] = HyperRecord::Collection.new([], self, relation)
            else
              @relations[relation] = self.class._convert_array_to_collection(record_hash[relation], self, relation)
            end
          else
            @relations[relation] = record_hash[relation]
          end
        else
          if reflections[relation][:kind] == :has_many
            @relations[relation] = HyperRecord::Collection.new([], self, relation)
          else
            @relations[relation] = nil
          end
          @fetch_states[relation] = 'n' # not fetched
        end
        record_hash.delete(relation)
      end

      @properties_hash = record_hash

      # change state
      _mutate_state

      # cache in global cache
      self.class._record_cache[@properties_hash[:id]] = self if @properties_hash.has_key?(:id)
    end

    ### reactive api

    def destroy
      destroy_record(observer)
      nil
    end

    def destroyed?
      @destroyed
    end

    def link(other_record)
      link_record(other_record, observer)
      self
    end

    def method_missing(method, arg)
      if method.end_with?('=')
        _register_observer
        @changed_properties_hash[method.chop] = arg
      else
        _register_observer
        return @changed_properties_hash[method] if @changed_properties_hash.has_key?(method)
        @properties_hash[method]
      end
    end

    def reflections
      self.class.reflections
    end

    def reset
      _register_observer
      @changed_properties_hash = {}
    end
    
    def resource_base_uri
      self.class.resource_base_uri
    end
    
    def rest_method_force_updates(method_name)
      @rest_methods_hash[method_name][:force] = true
    end

    def rest_method_unforce_updates(method_name)
      @rest_methods_hash[method_name][:force] = false
    end

    def save
      save_record(observer)
      self
    end

    def to_hash
      _register_observer
      @properties_hash.dup
    end

    def to_s
      _register_observer
      @properties_hash.to_s
    end

    def unlink(other_record)
      unlink_record(other_record, observer)
      self
    end
    
    ### promise api

    def destroy_record
      _local_destroy
      self.class._promise_delete("#{resource_base_uri}/#{@properties_hash[:id]}").then do |response|
        nil
      end.fail do |response|
        error_message = "Destroying record #{self} failed!"
        `console.error(error_message)`
        response
      end
    end

    def link_record(other_record, relation_name = nil)
      _register_observer
      called_from_collection = relation_name ? true : false
      relation_name = other_record.class.to_s.underscore.pluralize unless relation_name 
      raise "No relation for record of type #{other_record.class}" unless reflections.has_key?(relation_name)
      self.send(relation_name).push(other_record) unless called_from_collection
      payload_hash = other_record.to_hash
      self.class._promise_post("#{resource_base_uri}/#{self.id}/relations/#{relation_name}.json", { data: payload_hash }).then do |response|
        other_record.instance_variable_get(:@properties_hash).merge!(response.json[other_record.class.to_s.underscore])
        _notify_observers
        self
      end.fail do |response|
        error_message = "Linking record #{other_record} to #{self} failed!"
        `console.error(error_message)`
        response
      end
    end

    def save_record
      _register_observer
      payload_hash =  @properties_hash.merge(@changed_properties_hash) # copy hash, becasue we need to delete some keys
      (%i[id created_at updated_at] + reflections.keys).each do |key|
        payload_hash.delete(key)
      end
      if @properties_hash[:id] && ! (@changed_properties_hash.has_key?(:id) && @changed_properties_hash[:id].nil?)
        reset
        self.class._promise_patch("#{resource_base_uri}/#{@properties_hash[:id]}", { data: payload_hash }).then do |response|
          @properties_hash.merge!(response.json[self.class.to_s.underscore])
          _notify_observers
          self
        end.fail do |response|
          error_message = "Saving record #{self} failed!"
          `console.error(error_message)`
          response
        end
      else
        reset
        self.class._promise_post(resource_base_uri, { data: payload_hash }).then do |response|
          @properties_hash.merge!(response.json[self.class.to_s.underscore])
          _notify_observers
          self
        end.fail do |response|
          error_message = "Creating record #{self} failed!"
          `console.error(error_message)`
          response
        end
      end
    end

    def unlink_record(other_record, relation_name = nil)
      _register_observer
      called_from_collection = collection_name ? true : false
      relation_name = other_record.class.to_s.underscore.pluralize unless relation_name
      raise "No relation for record of type #{other_record.class}" unless reflections.has_key?(relation_name)
      self.send(relation_name).delete_if { |cr| cr == other_record } unless called_from_collection
      self.class._promise_delete("#{resource_base_uri}/#{@properties_hash[:id]}/relations/#{relation_name}.json?record_id=#{other_record.id}").then do |response|
        _notify_observers
        self
      end.fail do |response|
        error_message = "Unlinking #{other_record} from #{self} failed!"
        `console.log(error_message)`
        response
      end
    end

    ### internal

    def _local_destroy
      _register_observer
      @destroyed = true
      self.class._record_cache.delete(@properties_hash[:id])
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
      self.class._notify_klass_observers
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
          # are a workaround for safari, to get it updating correctly
          klass_name = data[:cause][:record_type]
          c_record_class = Object.const_get(klass_name)
          if c_record_class._record_cache.has_key?(data[:cause][:id])
            c_record = c_record_class.find(data[:cause][:id])
            if `Date.parse(#{c_record.updated_at}) >= Date.parse(#{data[:cause][:updated_at]})`
              if @fetch_states[data[:relation]] == 'f'
                if send(data[:relation]).include?(c_record) 
                  return
                end
              end
            end
          end
        end
        relation_fetch_state = @fetch_states[data[:relation]]
        if relation_fetch_state == 'f'
          @fetch_states[data[:relation]] = 'u'
          send(data[:relation])
        end
        return
      end
      if data[:destroyed]
        return if self.destroyed?
        @remotely_destroyed = true
        _local_destroy
        return
      end
      if @properties_hash[:updated_at] && data[:updated_at]
        return if `Date.parse(#{@properties_hash[:updated_at]}) >= Date.parse(#{data[:updated_at]})`
      end
      self.class._promise_get("#{resource_base_uri}/#{@properties_hash[:id]}.json").then do |response|
        klass_key = self.class.to_s.underscore
        self._initialize_from_hash(response.json[klass_key]) if response.json[klass_key]
        _notify_observers
        self
      end.fail do |response|
        error_message = "#{self} failed to update!"
        `console.log(error_message)`
        response
      end
    end
  end
end
