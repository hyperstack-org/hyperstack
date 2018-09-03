module Hyperstack
  module Record
    module ClientInstanceMethods

      # initialize a new instance of current Hyperstack::Record class
      #
      # @param record_hash [Hash] optional, initial values for properties
      def initialize(record_hash = {})
        # initalize internal data structures
        record_hash = {} if record_hash.nil?
        @properties = {}
        @changed_properties = {}
        @relations = {}
        @remote_methods = {}
        @collection_queries = {}
        @destroyed = false

        # for reactivity, possible @read_states:
        # n - not readed
        # f - readed
        # i - read in progress
        # u - update needed, read on next usage
        @read_states = {}
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
            @read_states[relation] = 'f' # readed
            if %i[has_many has_and_belongs_to_many].include?(reflections[relation][:kind])
              if record_hash[relation].nil?
                @relations[relation] = Hyperstack::Record::Collection.new([], self, relation)
              else
                @relations[relation] = Hyperstack::Model::Helpers.collection_from_transport_array(record_hash[relation], self, relation)
              end
            else
              @relations[relation] = Hyperstack::Model::Helpers.record_from_transport_hash(record_hash[relation])
            end
          else
            unless @read_states[relation] == 'f'
              if %i[has_many has_and_belongs_to_many].include?(reflections[relation][:kind])
                @relations[relation] = Hyperstack::Record::Collection.new([], self, relation)
              else
                @relations[relation] = nil
              end
              @read_states[relation] = 'n'
            end
          end
          record_hash.delete(relation)
        end

        @properties = record_hash

        # cache in global cache
        if @properties.has_key?(:id)
          @properties[:id] = @properties[:id].to_s
          self.class._record_cache[@properties[:id]] = self
        end
      end

      ### high level api

      # Check if record has been changed since last save.
      # @return boolean
      def changed?
        @changed_properties != {}
      end

      # destroy record, success is assumed
      # @return nil
      def destroy
        promise_destroy
        nil
      end

      # Check if record has been destroyed.
      # @return [Boolean]
      def destroyed?
        @destroyed
      end

      # record id, shortcut
      # @return [String]
      def id
        _register_observer
        if @changed_properties.has_key?(:id)
          @changed_properties[:id]
        else
          @properties[:id]
        end
      end

      # link the two records using a relation determined by other_record.class, success is assumed
      #
      # @param other_record [Hyperstack::Record]
      # @return [Hyperstack::Record] self
      def link(other_record)
        _register_observer
        promise_link(other_record)
        self
      end

      # method_missing is used for undeclared properties like in ActiveRecord models
      #
      # Two call signatures:
      # 1. the getter:
      # a_model.a_undeclared_property, returns the value of a_undeclared_property
      # 2. the setter:
      # a_model.a_undeclared_property = value, set a_undeclared_property to value, returns value
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

      # notify observers, will change state of observers, will also notify class observers
      #
      # @return nil
      def notify_observers
        @observers.each do |observer|
          React::State.set_state(observer, @state_key, `Date.now() + Math.random()`)
        end
        @observers = Set.new
        self.class.notify_class_observers
        nil
      end

      # introspection
      # @return [Hash]
      def reflections
        self.class.reflections
      end

      # reset properties to last saved value
      #
      # @return [Hyperstack::Record] self
      def reset
        _register_observer
        @changed_properties = {}
        self
      end

      # save record to db, success is assumed
      #
      # @return [Hyperstack::Record] self
      def save
        _register_observer
        promise_save
        self
      end

      # return record properties as Hash
      #
      # @return [Hash]
      def to_hash
        _register_observer
        @properties.dup.merge!(@changed_properties)
      end

      # return record properties as String
      #
      # @return [String]
      def to_s
        _register_observer
        @properties.dup.merge!(@changed_properties).to_s
      end

      # return record properties as hash, ready for transport
      #
      # @return [Hash]
      def to_transport_hash
        id_key = self.id ? self.id : "_new_#{`Date.now() + Math.random()`}"
        { self.class.model_name => { id_key => { properties: @properties.dup.merge!(@changed_properties) }}}
      end

      # unlink the two records using a relation determined by other_record.class, success is assumed
      #
      # @return [Hyperstack::Record] self
      def unlink(other_record)
        _register_observer
        promise_unlink(other_record)
        self
      end

      ### promise api

      # destroy record
      #
      # @return [Promise] on success the record is passed to the .then block
      #   on failure the .fail block will receive some error indicator or nothing
      def promise_destroy
        _local_destroy
        request = { 'hyperstack/handler/model/destroy' => { self.class.model_name => { instances: { id => { properties: self.to_transport_hash}}}}}
        Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
          self
        end.fail do |response|
          error_message = "Destroying record #{self} failed!"
          `console.error(error_message)`
          response
        end
      end

      # link the two records using a relation determined by other_record.class
      #
      # @param other_record [Hyperstack::Record]
      # @return [Promise] on success the record is passed to the .then block
      #   on failure the .fail block will receive some error indicator or nothing
      def promise_link(other_record, relation_name = nil)
        called_from_collection = relation_name ? true : false
        relation_name = other_record.class.to_s.underscore.pluralize unless relation_name
        if reflections.has_key?(relation_name)
          if !called_from_collection && @read_states[relation_name] == 'f'
            if %i[has_many has_and_belongs_to_many].include?(reflections[relation_name][:kind])
              @relations[relation_name] = Hyperstack::Record::Collection.new([], self, relation_name) if @relations[relation_name].nil?
              @relations[relation_name].push(other_record)
            else
              @relations[relation_name] = other_record
            end
          end
        else
          relation_name = other_record.class.to_s.underscore
          raise "No collection for record of type #{other_record.class}" unless reflections.has_key?(relation_name)
          if !called_from_collection && @read_states[relation_name] == 'f'
            if %i[has_many has_and_belongs_to_many].include?(reflections[relation_name][:kind])
              @relations[relation_name] = Hyperstack::Record::Collection.new([], self, relation_name) if @relations[relation_name].nil?
              @relations[relation_name].push(other_record)
            else
              @relations[relation_name] = other_record
            end
          end
        end

        request = { 'hyperstack/handler/model/link' => { self.class.model_name => { instances: { id => { relations: { relation_name => other_record.to_transport_hash }}}}}}
        Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
          self
        end.fail do |response|
          error_message = "Linking record #{other_record} to #{self} failed!"
          `console.error(error_message)`
          response
        end
      end

      # save record
      #
      # @return [Promise] on success the record is passed to the .then block
      #   on failure the .fail block will receive some error indicator or nothing
      def promise_save
        request = { 'hyperstack/handler/model/save' => self.to_transport_hash }
        is_new = @properties[:id].nil?
        Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
          self
        end.fail do |response|
          error_message = if is_new
                            "Creating record #{self} failed!"
                          else
                            "Saving record #{self} failed!"
                          end
          `console.error(error_message)`
          response
        end
      end

      # unlink the two records using a relation determined by other_record.class
      #
      # @param other_record [Hyperstack::Record]
      # @return [Promise] on success the record is passed to the .then block
      #   on failure the .fail block will receive some error indicator or nothing
      def promise_unlink(other_record, relation_name = nil)
        called_from_collection = collection_name ? true : false
        relation_name = other_record.class.to_s.underscore.pluralize unless relation_name
        raise "No relation for record of type #{other_record.class}" unless reflections.has_key?(relation_name)
        @relations[relation_name].delete_if { |cr| cr == other_record } if !called_from_collection && @read_states[relation_name] == 'f'
        request = { 'hyperstack/handler/model/unlink' => { self.class.model_name => { instances: { id => { relations: { relation_name => other_record.to_transport_hash }}}}}}
        Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
          self
        end.fail do |response|
          error_message = "Unlinking #{other_record} from #{self} failed!"
          `console.error(error_message)`
          response
        end
      end

      ### internal
      private

      # @private
      def _local_destroy
        _register_observer
        @destroyed = true
        self.class._record_cache.delete(@properties[:id].to_s)
        @registered_collections.dup.each do |collection|
          collection.delete(self)
        end
        @registered_collections = Set.new
        notify_observers
      end

      # @private
      def _register_collection(collection)
        @registered_collections << collection
      end

      # @private
      def _register_observer
        observer = React::State.current_observer
        if observer
          React::State.get_state(observer, @state_key)
          @observers << observer # @observers is a set, observers get added only once
        end
      end

      # @private
      def _unregister_collection(collection)
        @registered_collections.delete(collection)
      end

      # @private
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
                if @read_states[data[:relation]] == 'f'
                  if @relations[data[:relation]].include?(c_record)
                    return unless data[:cause][:destroyed]
                  end
                end
              end
            end
          end
          @read_states[data[:relation]] = 'u'
          send("promise_#{data[:relation]}").then do |collection|
            notify_observers
          end.fail do |response|
            error_message = "#{self}[#{self.id}].#{data[:relation]} failed to update!"
            `console.error(error_message)`
          end
          return
        end
        if data.has_key?(:remote_method)
          @read_states[data[:remote_method]] = 'u'
          if data[:remote_method].include?('_[')
            # remote_method with params
            notify_observers
          else
            # remote_method without params
            send("promise_#{data[:remote_method]}").then do |result|
              notify_observers
            end.fail do |response|
              error_message = "#{self}[#{self.id}].#{data[:remote_method]} failed to update!"
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
        self.class._class_read_states["record_#{id}"] = 'u'
        self.class.promise_find(@properties[:id], self).then do |record|
          notify_observers
          self
        end.fail do |response|
          error_message = "#{self} failed to update!"
          `console.error(error_message)`
        end
      end
    end
  end
end
