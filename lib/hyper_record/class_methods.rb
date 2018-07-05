module HyperRecord
  module ClassMethods

    # create a new instance of current HyperRecord class or return a existing one if a id in the hash is given
    #
    # @param record_hash [Hash] optional data for the record
    # @return [HyperRecord] the new instance or the existing one for a given id
    def new(record_hash = {})
      if record_hash.has_key?(:id)
        sid = record_hash[:id].to_s
        if _record_cache.has_key?(sid)
          record = _record_cache[sid]
          if record
            record._initialize_from_hash(record_hash)
            record._register_observer
            return record
          end
        end
      end
      super(record_hash)
    end

    # get api_path for this model. If it hans't been set, the global HyperRecord.api_path is used
    #
    # @return [String]
    def api_path
      @api_path ||= HyperRecord.api_path
    end

    # set api path for this model
    #
    # @return [String]
    def api_path=(api_path)
      @api_path = api_path
    end

    # get transport
    #
    # @return [String]
    def self.transport
      @transport ||= HyperRecord.transport
    end

    # set global api path
    #
    # @return [String]
    def self.transport=(transport)
      @transport = transport
    end

    # get global transport
    #
    # @return [String]
    def self.request_transducer
      @transducer ||= HyperRecord.transducer
    end

    # set global api path
    #
    # @return [String]
    def self.request_transducer=(transducer)
      @transducer = transducer
    end

    # DSL macro to declare a belongs_to relationship
    # options are for the server side ORM, on the client side options are ignored
    #
    # This macro defines additional methods:
    # promise_[relation_name]
    #    return [Promise] on success the .then block will receive a [HyperRecord::Collection] as arg
    #      on failure the .fail block will receive the HTTP response object as arg
    #
    # @param direction [String, Symbol] for ORMs like Neo4j: the direction of the graph edge, for ORMs like ActiveRecord: the name of the relation
    # @param relation_name [String, Symbol, Hash] for ORMs like Neo4j: the name of the relation, for ORMs like ActiveRecord: further options
    # @param options [Hash] further options for ORMs like Neo4j
    def belongs_to(direction, relation_name = nil, options = { type: nil })
      if relation_name.is_a?(Hash)
        options.merge(relation_name)
        relation_name = direction
        direction = nil
      elsif relation_name.is_a?(Proc)
        relation_name = direction
        direction = nil
      elsif relation_name.nil?
        relation_name = direction
      end
      reflections[relation_name] = { direction: direction, type: options[:type], kind: :belongs_to }

      define_method("promise_#{relation_name}") do
        _register_observer
        @fetch_states[relation_name] = 'i'
        request = self.class.request_transducer.fetch(self.class.model_name => { instances: { id => { relations: { relation_name => nil }}}})
        self.class.transport.promise_send(request).then do |response|
          @relations[relation_name] = if response.json[self.class.model_name][relation_name]
                               self.class._convert_json_hash_to_record(response.json[self.class.model_name][relation_name])
                             else
                               nil
                             end
          @fetch_states[relation_name] = 'f'
          notify_observers
          self
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a belongs_to association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      # @!method [relation_name] get records of the relation
      # @return [HyperRecord::Collection] either a empty one, if the data has not been fetched yet, or the
      #   collection with the real data, if it has been fetched already
      define_method(relation_name) do
        if @fetch_states[relation_name] == 'i'
          _register_observer
        elsif self.id && @fetch_states[relation_name] != 'f'
          send("promise_#{relation_name}")
        end
        @relations[relation_name]
      end
      # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
      # @return nil
      define_method("update_#{relation_name}") do
        @fetch_states[relation_name] = 'u'
        nil
      end
      # TODO, needs the network part, post to server
      # define_method("#{name}=") do |arg|
      #   _register_observer
      #   @relations[name] = arg
      #   @fetch_states[name] = 'f'
      #   @relations[name]
      # end
    end

    # create a new instance of current HyperRecord class and save it to the db
    #
    # @param record_hash [Hash] optional data for the record
    # @return [HyperRecord] the new instance
    def create(record_hash = {})
      record = new(record_hash)
      record.save
    end

    # create a new instance of current HyperRecord class and save it to the db
    #
    # @param record_hash [Hash] optional data for the record
    # @return [Promise] on success the .then block will receive the new HyperRecord instance as arg
    #   on failure the .fail block will receive the HTTP response object as arg
    def promise_create(record_hash = {})
      record = new(record_hash)
      record.promise_save
    end

    # find a existing instance of current HyperRecord class
    #
    # @param id [String] id of the record to find
    # @return [HyperRecord]
    def find(id)
      sid = id.to_s
      return nil if sid == ''
      record_sid = "record_#{sid}"
      if _record_cache.has_key?(sid)
        _register_class_observer if _class_fetch_states[record_sid] == 'i'
        return _record_cache[sid] if 'fi'.include?(_class_fetch_states[record_sid])
      end
      record_in_progress = if _record_cache.has_key?(sid)
                             _record_cache[sid]
                           else
                             self.new(id: sid)
                           end
      promise_find(sid)
      record_in_progress
    end

    # find a existing instance of current HyperRecord class
    #
    # @param id [String] id of the record to find
    # @return [Promise] on success the .then block will receive the new HyperRecord instance as arg
    #   on failure the .fail block will receive the HTTP response object as arg
    def promise_find(id)
      sid = id.to_s
      record_sid = "record_#{sid}"
      _class_fetch_states[record_sid] = 'i'
      request = request_transducer.fetch(self.class.model_name => { id: sid })
      _register_class_observer
      transport.promise_send(request).then do |response|
        klass_key = self.to_s.underscore
        record = self.new(response.json[klass_key]) if response.json[klass_key]
        _class_fetch_states[record_sid] = 'f'
        notify_class_observers
        record
      end.fail do |response|
        error_message = "#{self.to_s}.find(#{sid}) failed to fetch record!"
        `console.error(error_message)`
        response
      end
    end

    # find a existing instance of current HyperRecord class by property value
    #
    # @param property_value_hash [Hash] hash with the values to find
    # @return [Promise] on success the .then block will receive the new HyperRecord instance as arg
    #   on failure the .fail block will receive the HTTP response object as arg
    # def promise_find_by(property_value_hash)
    #   request = request_transducer.fetch(self.class.model_name => { properties: property_value_hash })
    #   _register_class_observer
    #   transport.promise_send(request).then do |response|
    #     klass_key = self.to_s.underscore
    #     record = self.new(response.json[klass_key]) if response.json[klass_key]
    #     record_sid = "record_#{record.id}"
    #     _class_fetch_states[record_sid] = 'f'
    #     notify_class_observers
    #     record
    #   end.fail do |response|
    #     error_message = "#{self.to_s}.find(#{id}) failed to fetch record!"
    #     `console.error(error_message)`
    #     response
    #   end
    # end

    # DSL macro to declare a has_and_belongs_many relationship
    # options are for the server side ORM, on the client side options are ignored
    #
    # @param direction [String] or [Symbol] for ORMs like Neo4j: the direction of the graph edge, for ORMs like ActiveRecord: the name of the relation
    # @param relation_name [String] or [Symbol] or [Hash] for ORMs like Neo4j: the name of the relation, for ORMs like ActiveRecord: further options
    # @param options [Hash] further options for ORMs like Neo4j
    #
    # This macro defines additional methods:
    def has_and_belongs_to_many(direction, relation_name = nil, options = { type: nil })
      if relation_name.is_a?(Hash)
        options.merge(relation_name)
        relation_name = direction
        direction = nil
      elsif relation_name.is_a?(Proc)
        relation_name = direction
        direction = nil
      elsif relation_name.nil?
        relation_name = direction
      end
      reflections[relation_name] = { direction: direction, type: options[:type], kind: :has_and_belongs_to_many }
      # @!method promise_[relation_name]
      # @return [Promise] on success the .then block will receive a [HyperRecord::Collection] as arg
      #    on failure the .fail block will receive the HTTP response object as arg
      define_method("promise_#{relation_name}") do
        _register_observer
        @fetch_states[relation_name] = 'i'
        request = self.class.request_transducer.fetch(self.class.model_name => { instances: { id => { relations: { relation_name => nil }}}})
        self.class.transport.promise_send(request).then do |response|
          collection = self.class._convert_array_to_collection(response.json[self.class.to_s.underscore][relation_name], self, relation_name)
          @relations[relation_name] = collection
          @fetch_states[relation_name] = 'f'
          notify_observers
          self
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a has_and_belongs_to_many association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      # @!method [relation_name] get records of the relation
      # @return [HyperRecord::Collection] either a empty one, if the data has not been fetched yet, or the
      #   collection with the real data, if it has been fetched already
      define_method(relation_name) do
        if @fetch_states[relation_name] == 'i'
          _register_observer
        elsif self.id && @fetch_states[relation_name] != 'f'
          send("promise_#{relation_name}")
        end
        @relations[relation_name]
      end
      # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
      # @return nil
      define_method("update_#{relation_name}") do
        @fetch_states[relation_name] = 'u'
        nil
      end
      # TODO
      # define_method("#{name}=") do |arg|
      #   _register_observer
      #   collection = if arg.is_a?(Array)
      #                  HyperRecord::Collection.new(arg, self, name)
      #                elsif arg.is_a?(HyperRecord::Collection)
      #                  arg
      #                else
      #                  raise "Argument must be a HyperRecord::Collection or a Array"
      #                end
      #   @relations[name] = collection
      #   @fetch_states[name] = 'f'
      #   @relations[name]
      # end
    end

    # DSL macro to declare a has_many relationship
    # options are for the server side ORM, on the client side options are ignored
    #
    # @param direction [String] or [Symbol] for ORMs like Neo4j: the direction of the graph edge, for ORMs like ActiveRecord: the name of the relation
    # @param relation_name [String] or [Symbol] or [Hash] for ORMs like Neo4j: the name of the relation, for ORMs like ActiveRecord: further options
    # @param options [Hash] further options for ORMs like Neo4j
    #
    # This macro defines additional methods:
    def has_many(direction, relation_name = nil, options = { type: nil })
      if relation_name.is_a?(Hash)
        options.merge(relation_name)
        relation_name = direction
        direction = nil
      elsif relation_name.is_a?(Proc)
        relation_name = direction
        direction = nil
      elsif relation_name.nil?
        relation_name = direction
      end
      reflections[relation_name] = { direction: direction, type: options[:type], kind: :has_many }
      # @!method promise_[relation_name]
      # @return [Promise] on success the .then block will receive a [HyperRecord::Collection] as arg
      #    on failure the .fail block will receive the HTTP response object as arg
      define_method("promise_#{relation_name}") do
        _register_observer
        @fetch_states[relation_name] = 'i'
        request = self.class.request_transducer.fetch(self.class.model_name => { instances: { id => { relations: { relation_name => nil }}}})
        self.class.transport.promise_send(request).then do |response|
          collection = self.class._convert_array_to_collection(response.json[self.class.to_s.underscore][relation_name], self, relation_name)
          @relations[relation_name] = collection
          @fetch_states[relation_name] = 'f'
          notify_observers
          @relations[relation_name]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a has_many association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      # @!method [relation_name] get records of the relation
      # @return [HyperRecord::Collection] either a empty one, if the data has not been fetched yet, or the
      #   collection with the real data, if it has been fetched already
      define_method(relation_name) do
        if @fetch_states[relation_name] == 'i'
          _register_observer
        elsif self.id && @fetch_states[relation_name] != 'f'
          send("promise_#{relation_name}")
        end
        @relations[relation_name]
      end
      # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
      # @return nil
      define_method("update_#{relation_name}") do
        @fetch_states[relation_name] = 'u'
        nil
      end
      # define_method("#{relation_name}=") do |arg|
      #   _register_observer
      #   collection = if arg.is_a?(Array)
      #     HyperRecord::Collection.new(arg, self, relation_name)
      #   elsif arg.is_a?(HyperRecord::Collection)
      #     arg
      #   else
      #     raise "Argument must be a HyperRecord::Collection or a Array"
      #   end
      #   @relations[relation_name] = collection
      #   @fetch_states[relation_name] = 'f'
      #   @relations[relation_name]
      # end
    end

    # DSL macro to declare a has_one relationship
    # options are for the server side ORM, on the client side options are ignored
    #
    # @param direction [String] or [Symbol] for ORMs like Neo4j: the direction of the graph edge, for ORMs like ActiveRecord: the name of the relation
    # @param relation_name [String] or [Symbol] or [Hash] for ORMs like Neo4j: the name of the relation, for ORMs like ActiveRecord: further options
    # @param options [Hash] further options for ORMs like Neo4j
    #
    # This macro defines additional methods:
    def has_one(direction, relation_name, options = { type: nil })
      if relation_name.is_a?(Hash)
        options.merge(relation_name)
        relation_name = direction
        direction = nil
      elsif relation_name.is_a?(Proc)
        relation_name = direction
        direction = nil
      elsif relation_name.nil?
        relation_name = direction
      end
      reflections[relation_name] = { direction: direction, type: options[:type], kind: :has_one }
      # @!method promise_[relation_name]
      # @return [Promise] on success the .then block will receive a [HyperRecord::Collection] as arg
      #    on failure the .fail block will receive the HTTP response object as arg
      define_method("promise_#{relation_name}") do
        @fetch_states[relation_name] = 'i'
        request = self.class.request_transducer.fetch(self.class.model_name => { instances: { id => { relations: { relation_name => nil }}}})
        self.class.transport.promise_send(request).then do |response|
          @relations[relation_name] = self.class._convert_json_hash_to_record(response.json[self.class.to_s.underscore][relation_name])
          @fetch_states[relation_name] = 'f'
          notify_observers
          @relations[relation_name]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a has_one association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      # @!method [relation_name] get records of the relation
      # @return [HyperRecord::Collection] either a empty one, if the data has not been fetched yet, or the
      #   collection with the real data, if it has been fetched already
      define_method(relation_name) do
        if @fetch_states[relation_name] == 'i'
          _register_observer
        elsif self.id && @fetch_states[relation_name] != 'f'
          send("promise_#{relation_name}")
        end
        @relations[relation_name]
      end
      # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
      # @return nil
      define_method("update_#{relation_name}") do
        @fetch_states[relation_name] = 'u'
        nil
      end
      # define_method("#{relation_name}=") do |arg|
      #   _register_observer
      #   @relations[relation_name] = arg
      #   @fetch_states[relation_name] = 'f'
      #   @relations[relation_name]
      # end
    end

    # get model_name
    # @return [String]
    def model_name
      @model_name ||= self.to_s.underscore
    end

    # notify class observers, will change state of observers
    # @return nil
    def notify_class_observers
      _class_observers.each do |observer|
        React::State.set_state(observer, _class_state_key, `Date.now() + Math.random()`)
      end
      _class_observers = Set.new
      nil
    end

    # check if a record of current HyperRecord class has been cached already
    # @param id [String]
    def record_cached?(id)
      _record_cache.has_key?(id.to_s)
    end

    # declare a property (attribute) for the current HyperRecord class
    # @param name [String] or [Symbol]
    # @param options [Hash] following keys are known:
    #   default: a default value to present during render if no other value is known
    #   type: type for a HyperRecord::DummyValue in case no default or other value is known
    #
    # This macro defines additional methods:
    def property(name, options = {})
      _property_options[name] = options
      # @!method [name] a getter for the property
      define_method(name) do
        _register_observer
        if @properties[:id]
          if @changed_properties.has_key?(name)
            @changed_properties[name]
          else
            @properties[name]
          end
        else
          # record has not been fetched or is new and not yet saved
          if @properties[name].nil?
            # TODO move default to initializer?
            if self.class._property_options[name].has_key?(:default)
              self.class._property_options[name][:default]
            elsif self.class._property_options[name].has_key?(:type)
              HyperRecord::DummyValue.new(self.class._property_options[name][:type])
            else
              HyperRecord::DummyValue.new(NilClass)
            end
          else
            @properties[name]
          end
        end
      end
      # @!method [name]= a setter for the property
      # @param value the new value for the property
      define_method("#{name}=") do |value|
        _register_observer
        @changed_properties[name] = value
      end
    end

    # introspect on current HyperRecord class
    # @return [Hash]
    def reflections
      @reflections ||= {}
    end

    # macro define rest_class_methods, RPC on class level of current HyperRecord class
    #
    # @param name [Symbol] name of method
    # @param options [Hash] with known keys:
    #   default_result: result to present during render during method call in progress
    #
    # This macro defines additional methods:
    def rest_class_method(name, options = { default_result: '...' })
      rest_class_methods[name] = options
      # @!method promise_[name]
      # @return [Promise] on success the .then block will receive the result of the RPC call as arg
      #    on failure the .fail block will receive the HTTP response object as arg
      define_singleton_method("promise_#{name}") do |*args|
        name_args = _name_args(name, *args)
        _class_fetch_states[name_args] = 'i'
        rest_class_methods[name_args] = { result: options[:default_result] } unless rest_class_methods.has_key?(name_args)
        request = request_transducer.fetch(self.class.model_name => { methods: { method_name => args }})
        transport.promise_send(request).then do |response_json|
          rest_class_methods[name_args][:result] = response_json[:result] # result is parsed json
          _class_fetch_states[name_args] = 'f'
          notify_class_observers
          rest_class_methods[name_args][:result]
        end.fail do |response|
          error_message = "#{self.to_s}.#{name}, a rest_method, failed to execute!"
          `console.error(error_message)`
          response
        end
      end
      # @!method [name]
      # @return result either the default_result ass specified in the options or the real result if the RPC call already finished
      define_singleton_method(name) do |*args|
        name_args = _name_args(name, *args)
        _register_class_observer
        rest_class_methods[name_args] = { result: options[:default_result] } unless rest_class_methods.has_key?(name_args)
        unless _class_fetch_states.has_key?(name_args) && 'fi'.include?(_class_fetch_states[name_args])
          self.send("promise_#{name}", *args)
        end
        rest_class_methods[name_args][:result]
      end
      # @!method update_[name] mark internal structures so that the method is called again once it is requested again
      # @return nil
      define_singleton_method("update_#{name}") do |*args|
        _class_fetch_states[_name_args(name, *args)] = 'u'
        nil
      end
    end

    # macro define rest_class_methods, RPC on instance level of a record of current HyperRecord class
    #
    # @param name [Symbol] name of method
    # @param options [Hash] with known keys:
    #   default_result: result to present during render during method call in progress
    #
    # This macro defines additional methods:
    def rest_method(name, options = { default_result: '...' })
      # @!method promise_[name]
      # @return [Promise] on success the .then block will receive the result of the RPC call as arg
      #    on failure the .fail block will receive the HTTP response object as arg
      define_method("promise_#{name}") do |*args|
        name_args = self.class._name_args(name, *args)
        @fetch_states[name_args] = 'i'
        @rest_methods[name] = options unless @rest_methods.has_key?(name)
        @rest_methods[name_args] = { result: options[:default_result] } unless @rest_methods.has_key?(name_args)
        raise "#{self.class.to_s}[_no_id_].#{name}, can't execute instance rest_method without id!" unless self.id
        request = self.class.request_transducer.fetch(self.class.model_name => { instances: { id => { methods: { method_name => args }}}})
        self.class.transport.promise_send(request).then do |response_json|
          @rest_methods[name_args][:result] = response_json[:result] # result is parsed json
          @fetch_states[name_args] = 'f'
          notify_observers
          @rest_methods[name_args][:result]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{name}, a rest_method, failed to execute!"
          `console.error(error_message)`
          response
        end
      end
      # @!method [name]
      # @return result either the default_result ass specified in the options or the real result if the RPC call already finished
      define_method(name) do |*args|
        _register_observer
        name_args = self.class._name_args(name, *args)
        @rest_methods[name] = options unless @rest_methods.has_key?(name)
        @rest_methods[name_args] = { result: options[:default_result] } unless @rest_methods.has_key?(name_args)
        unless @fetch_states.has_key?(name_args) && 'fi'.include?(@fetch_states[name_args])
          self.send("promise_#{name}", *args)
        end
        @rest_methods[name_args][:result]
      end
      # @!method update_[name] mark internal structures so that the method is called again once it is requested again
      # @return nil
      define_method("update_#{name}") do |*args|
        @fetch_states[self.class._name_args(name, *args)] = 'u'
        nil
      end
    end

    # introspect on available rest_class_methods
    # @return [Hash]
    def rest_class_methods
      @rest_class_methods ||= {}
    end

    # DSL macro to declare a scope
    # options are for the server side ORM, on the client side options are ignored
    #
    # @param name [String] or [Symbol] the name of the relation
    # @param options [Hash] further options
    #
    # This macro defines additional methods:
    def scope(name, options = {})
      # @!method promise_[name]
      # @return [Promise] on success the .then block will receive a [HyperRecord::Collection] as arg
      #    on failure the .fail block will receive the HTTP response object as arg
      define_singleton_method("promise_#{name}") do |*args|
        name_args = _name_args(name, *args)
        _class_fetch_states[name_args] = 'i'
        request = request_transducer.fetch(self.class.model_name => { scopes: { scope_name => args }})
        promise_send(request).then do |response_json|
          scopes[name_args] = _convert_array_to_collection(response_json[self.to_s.underscore][name])
          _class_fetch_states[name_args] = 'f'
          notify_class_observers
          scopes[name_args]
        end.fail do |response|
          error_message = "#{self.to_s}.#{name_args}, a scope, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      # @!method [name] get records of the scope
      # @return [HyperRecord::Collection] either a empty one, if the data has not been fetched yet, or the
      #   collection with the real data, if it has been fetched already
      define_singleton_method(name) do |*args|
        name_args = _name_args(name, *args)
        scopes[name_args] = HyperRecord::Collection.new unless scopes.has_key?(name_args)
        _register_class_observer
        unless _class_fetch_states.has_key?(name_args) && 'fi'.include?(_class_fetch_states[name_args])
          self.send("promise_#{name}", *args)
        end
        scopes[name_args]
      end
      # @!method update_[name] mark internal structures so that the scope data is updated once it is requested again
      # @return nil
      define_singleton_method("update_#{name}") do |*args|
        _class_fetch_states[_name_args(name, *args)] = 'u'
        nil
      end
    end

    # introspect on available scopes
    # @return [Hash]
    def scopes
      @scopes ||= {}
    end


    private
    # internal, should not be used in application code

    # @private
    def _convert_array_to_collection(array, record = nil, relation_name = nil)
      res = array.map do |record_hash|
        _convert_json_hash_to_record(record_hash)
      end
      HyperRecord::Collection.new(res, record, relation_name)
    end

    # @private
    def _convert_json_hash_to_record(record_hash)
      return nil if !record_hash
      klass_key = record_hash.keys.first
      return nil if klass_key == "nil_class"
      return nil if !record_hash[klass_key]
      return nil if record_hash[klass_key].keys.size == 0
      record_class = klass_key.camelize.constantize
      if record_hash[klass_key][:id].nil?
        record_class.new(record_hash[klass_key])
      else
        record = record_class._record_cache[record_hash[klass_key][:id].to_s]
        if record.nil?
          record = record_class.new(record_hash[klass_key])
        else
          record._initialize_from_hash(record_hash[klass_key])
        end
        record.class._class_fetch_states["record_#{record.id}"] = 'f'
        record
      end
    end

    # @private
    def _class_fetch_states
      @_class_fetch_states ||= { all: 'n' }
      @_class_fetch_states
    end

    # @private
    def _class_observers
      @_class_observers ||= Set.new
      @_class_observers
    end

    # @private
    def _class_state_key
      @_class_state_key ||= self.to_s
      @_class_state_key
    end

    # @private
    def _name_args(name, *args)
      if args.size > 0
        "#{name}_#{args.to_json}"
      else
        name
      end
    end

    # @private
    def _property_options
      @property_options ||= {}
    end

    # @private
    def _record_cache
      @record_cache ||= {}
    end

    # @private
    def _register_class_observer
      observer = React::State.current_observer
      if observer
        React::State.get_state(observer, _class_state_key)
        _class_observers << observer # @observers is a set, observers get added only once
      end
    end
  end
end
