module Hyperstack
  module Record
    module ClientClassMethods

      # create a new instance of current Hyperstack::Record class or return a existing one if a id in the hash is given
      #
      # @param record_hash [Hash] optional data for the record
      # @return [Hyperstack::Record] the new instance or the existing one for a given id
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

      def hyperstack_orm_driver
        @orm_driver ||= Hyperstack::Model::Driver::ActiveRecord.new(self)
      end

      def hyperstack_orm_driver=(driver)
        @orm_driver = driver.new(self)
      end

      # DSL macro to declare a belongs_to relationship
      # options are for the server side ORM, on the client side options are ignored
      #
      # This macro defines additional methods:
      # promise_[relation_name]
      #    return [Promise] on success the .then block will receive a [Hyperstack::Record::Collection] as arg
      #      on failure the .fail block will receive some error indicator or nothing
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
          @read_states[relation_name] = 'i'
          request = { 'hyperstack/handler/model/read' => { self.class.model_name => { instances: { id => { relations: { relation_name => {}}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            self
          end.fail do |response|
            error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a belongs_to association, failed to read records!"
            `console.error(error_message)`
            response
          end
        end
        # @!method [relation_name] get records of the relation
        # @return [Hyperstack::Record::Collection] either a empty one, if the data has not been readed yet, or the
        #   collection with the real data, if it has been readed already
        define_method(relation_name) do
          if @read_states[relation_name] == 'i'
            _register_observer
          elsif self.id && @read_states[relation_name] != 'f'
            send("promise_#{relation_name}")
          end
          @relations[relation_name]
        end
        # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
        # @return nil
        define_method("update_#{relation_name}") do
          @read_states[relation_name] = 'u'
          nil
        end
        # TODO, needs the network part, post to server
        # define_method("#{name}=") do |arg|
        #   _register_observer
        #   @relations[name] = arg
        #   @read_states[name] = 'f'
        #   @relations[name]
        # end
      end

      def collection_queries
        @_collection_queries ||= {}
      end
      # macro define collection_query, RPC on instance level of a record of current Hyperstack::Record class
      # The supplied block must return a Array of Records!
      #
      # @param name [Symbol] name of method
      #
      # This macro defines additional methods:
      def collection_query(name)
        # @!method promise_[name]
        # @return [Promise] on success the .then block will receive the result of the RPC call as arg
        #    on failure the .fail block will receive some error indicator or nothing
        collection_queries[name] = {}
        define_method("promise_#{name}") do
          @read_states[name] = 'i'
          unless @collection_queries.has_key?(name)
            @collection_queries[name][:result] = Hyperstack::Record::Collection.new([], self)
            @update_on_link[name] = {}
          end
          raise "#{self.class.to_s}[_no_id_].#{name}, can't execute instance collection_query without id!" unless self.id
          request = { 'hyperstack/handler/model/read' => { self.class.model_name => { instances: { id => { collection_queries: { name => {}}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            @collection_query[name][:result]
          end.fail do |response|
            error_message = "#{self.class.to_s}[#{self.id}].#{name}, a collection_query, failed to execute!"
            `console.error(error_message)`
            response
          end
        end
        # @!method [name]
        # @return result either the default_result ass specified in the options or the real result if the RPC call already finished
        define_method(name) do
          unless self.id
            options[:default_result]
          else
            _register_observer
            unless @collection_query.has_key?(name)
              @collection_queries[name][:result] = Hyperstack::Record::Collection.new([], self)
              @update_on_link[name] = {}
            end
            unless @read_states.has_key?(name) && 'fi'.include?(@read_states[name])
              self.send("promise_#{name}")
            end
          end
          @remote_methods[name][:result]
        end
        # @!method update_[name] mark internal structures so that the method is called again once it is requested again
        # @return nil
        define_method("update_#{name}") do
          @read_states[name] = 'u'
          nil
        end
      end

      # create a new instance of current Hyperstack::Record class and save it to the db
      #
      # @param record_hash [Hash] optional data for the record
      # @return [Hyperstack::Record] the new instance
      def create(record_hash = {})
        record = new(record_hash)
        record.save
      end

      # create a new instance of current Hyperstack::Record class and save it to the db
      #
      # @param record_hash [Hash] optional data for the record
      # @return [Promise] on success the .then block will receive the new Hyperstack::Record instance as arg
      #   on failure the .fail block will receive some error indicator or nothing
      def promise_create(record_hash = {})
        record = new(record_hash)
        record.promise_save
      end

      # find a existing instance of current Hyperstack::Record class
      #
      # @param id [String] id of the record to find
      # @return [Hyperstack::Record]
      def find(id)
        return nil if !id || id.respond_to?(:is_dummy?)
        sid = id.to_s
        return nil if sid == ''
        record_sid = "record_#{sid}"
        if _record_cache.has_key?(sid) && _class_read_states.has_key?(record_sid)
          _register_class_observer if _class_read_states[record_sid] == 'i'
          return _record_cache[sid] if 'fi'.include?(_class_read_states[record_sid])
        end
        record_in_progress = if _record_cache.has_key?(sid)
                               _record_cache[sid]
                             else
                               self.new(id: sid)
                             end
        promise_find(sid)
        record_in_progress
      end

      # find a existing instance of current Hyperstack::Record class
      #
      # @param id [String] id of the record to find
      # @return [Promise] on success the .then block will receive the new Hyperstack::Record instance as arg
      #   on failure the .fail block will receive some error indicator or nothing
      def promise_find(id)
        sid = id.to_s
        record_sid = "record_#{sid}"
        _class_read_states[record_sid] = 'i'
        request = { 'hyperstack/handler/model/read' => { self.model_name => { instances: { sid => {}}}}}
        _register_class_observer
        Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
          notify_class_observers
          _record_cache[sid]
        end.fail do |response|
          error_message = "#{self.to_s}.find(#{sid}) failed to read record!"
          `console.error(error_message)`
          response
        end
      end

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
        # @return [Promise] on success the .then block will receive a [Hyperstack::Record::Collection] as arg
        #    on failure the .fail block will receive some error indicator or nothing
        define_method("promise_#{relation_name}") do
          _register_observer
          @read_states[relation_name] = 'i'
          request = { 'hyperstack/handler/model/read' => { self.class.model_name => { instances: { id => { relations: { relation_name => {}}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            self
          end.fail do |response|
            error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a has_and_belongs_to_many association, failed to read records!"
            `console.error(error_message)`
            response
          end
        end
        # @!method [relation_name] get records of the relation
        # @return [Hyperstack::Record::Collection] either a empty one, if the data has not been readed yet, or the
        #   collection with the real data, if it has been readed already
        define_method(relation_name) do
          if @read_states[relation_name] == 'i'
            _register_observer
          elsif self.id && @read_states[relation_name] != 'f'
            send("promise_#{relation_name}")
          end
          @relations[relation_name]
        end
        # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
        # @return nil
        define_method("update_#{relation_name}") do
          @read_states[relation_name] = 'u'
          nil
        end
        # TODO
        # define_method("#{name}=") do |arg|
        #   _register_observer
        #   collection = if arg.is_a?(Array)
        #                  Hyperstack::Record::Collection.new(arg, self, name)
        #                elsif arg.is_a?(Hyperstack::Record::Collection)
        #                  arg
        #                else
        #                  raise "Argument must be a Hyperstack::Record::Collection or a Array"
        #                end
        #   @relations[name] = collection
        #   @read_states[name] = 'f'
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
        # @return [Promise] on success the .then block will receive a [Hyperstack::Record::Collection] as arg
        #    on failure the .fail block will receive some error indicator or nothing
        define_method("promise_#{relation_name}") do
          _register_observer
          @read_states[relation_name] = 'i'
          request = { 'hyperstack/handler/model/read' => { self.class.model_name => { instances: { id => { relations: { relation_name => {}}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            self
          end.fail do |response|
            error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a has_many association, failed to read records!"
            `console.error(error_message)`
            response
          end
        end
        # @!method [relation_name] get records of the relation
        # @return [Hyperstack::Record::Collection] either a empty one, if the data has not been readed yet, or the
        #   collection with the real data, if it has been readed already
        define_method(relation_name) do
          if @read_states[relation_name] == 'i'
            _register_observer
          elsif self.id && @read_states[relation_name] != 'f'
            send("promise_#{relation_name}")
          end
          @relations[relation_name]
        end
        # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
        # @return nil
        define_method("update_#{relation_name}") do
          @read_states[relation_name] = 'u'
          nil
        end
        # define_method("#{relation_name}=") do |arg|
        #   _register_observer
        #   collection = if arg.is_a?(Array)
        #     Hyperstack::Record::Collection.new(arg, self, relation_name)
        #   elsif arg.is_a?(Hyperstack::Record::Collection)
        #     arg
        #   else
        #     raise "Argument must be a Hyperstack::Record::Collection or a Array"
        #   end
        #   @relations[relation_name] = collection
        #   @read_states[relation_name] = 'f'
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
        # @return [Promise] on success the .then block will receive a [Hyperstack::Record::Collection] as arg
        #    on failure the .fail block will receive some error indicator or nothing
        define_method("promise_#{relation_name}") do
          @read_states[relation_name] = 'i'
          request = { 'hyperstack/handler/model/read' => { self.class.model_name => { instances: { id => { relations: { relation_name => {}}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            self
          end.fail do |response|
            error_message = "#{self.class.to_s}[#{self.id}].#{relation_name}, a has_one association, failed to read records!"
            `console.error(error_message)`
            response
          end
        end
        # @!method [relation_name] get records of the relation
        # @return [Hyperstack::Record::Collection] either a empty one, if the data has not been readed yet, or the
        #   collection with the real data, if it has been readed already
        define_method(relation_name) do
          if @read_states[relation_name] == 'i'
            _register_observer
          elsif self.id && @read_states[relation_name] != 'f'
            send("promise_#{relation_name}")
          end
          @relations[relation_name]
        end
        # @!method update_[relation_name] mark internal structures so that the relation data is updated once it is requested again
        # @return nil
        define_method("update_#{relation_name}") do
          @read_states[relation_name] = 'u'
          nil
        end
        # define_method("#{relation_name}=") do |arg|
        #   _register_observer
        #   @relations[relation_name] = arg
        #   @read_states[relation_name] = 'f'
        #   @relations[relation_name]
        # end
      end

      alias _original_method_missing method_missing

      # @!method promise_find_by find a record by attribute
      #
      # @param property_hash [Hash]
      #
      # @return [Promise] on success the .then block will receive a [Hyperstack::Record] as arg
      #    on failure the .fail block will receive some error indicator or nothing
      def method_missing(method_name, *args, &block)
        if method_name.start_with?('promise_find_by')
          handler_method_name = method_name.sub('promise_', '')
          agent = Hyperstack::Transport::RequestAgent.new
          request = { 'hyperstack/handler/model/read' => { self.model_name => { find_by: { agent.object_id => { handler_method_name => args }}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            raise if agent.errors
            agent.result
          end.fail do |response|
            error_message = "#{self.to_s}.#{method_name}(#{args}) failed, #{agent.errors}!"
            `console.error(error_message)`
            response
          end
        else
          super
        end
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

      # declare a property (attribute) for the current Hyperstack::Record class
      # @param name [String] or [Symbol]
      # @param options [Hash] following keys are known:
      #   default: a default value to present during render if no other value is known
      #   type: type for a Hyperstack::Record::DummyValue in case no default or other value is known
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
            # record has not been readed or is new and not yet saved
            if @properties[name].nil?
              # TODO move default to initializer?
              if self.class._property_options[name].has_key?(:default)
                self.class._property_options[name][:default]
              elsif self.class._property_options[name].has_key?(:type)
                Hyperstack::Record::DummyValue.new(self.class._property_options[name][:type])
              else
                Hyperstack::Record::DummyValue.new(NilClass)
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

      # check if a record of current Hyperstack::Record class has been cached already
      # @param id [String]
      def record_cached?(id)
        _record_cache.has_key?(id.to_s)
      end

      # introspect on current Hyperstack::Record class
      # @return [Hash]
      def reflections
        @reflections ||= {}
      end

      def respond_to?(method_name, include_private = false)
        method_name.start_with?('promise_find_by') || super
      end

      # macro define rest_class_methods, RPC on class level of current Hyperstack::Record class
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
        #    on failure the .fail block will receive some error indicator or nothing
        define_singleton_method("promise_#{name}") do |*args|
          name_args = _name_args(name, *args)
          _class_read_states[name_args] = 'i'
          rest_class_methods[name_args] = { result: options[:default_result] } unless rest_class_methods.has_key?(name_args)
          request = { 'hyperstack/handler/model/read' => { self.model_name => { remote_methods: { name =>{ args => {}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            rest_class_methods[name_args][:result]
          end.fail do |response|
            error_message = "#{self.to_s}.#{name}, a remote_method, failed to execute!"
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
          unless _class_read_states.has_key?(name_args) && 'fi'.include?(_class_read_states[name_args])
            self.send("promise_#{name}", *args)
          end
          rest_class_methods[name_args][:result]
        end
        # @!method update_[name] mark internal structures so that the method is called again once it is requested again
        # @return nil
        define_singleton_method("update_#{name}") do |*args|
          _class_read_states[_name_args(name, *args)] = 'u'
          nil
        end
      end

      # macro define rest_class_methods, RPC on instance level of a record of current Hyperstack::Record class
      #
      # @param name [Symbol] name of method
      # @param options [Hash] with known keys:
      #   default_result: result to present during render during method call in progress
      #
      # This macro defines additional methods:
      def remote_method(name, options = { default_result: '...' })
        # @!method promise_[name]
        # @return [Promise] on success the .then block will receive the result of the RPC call as arg
        #    on failure the .fail block will receive some error indicator or nothing
        define_method("promise_#{name}") do |*args|
          args_json = args.to_json
          @read_states[name] = {} unless @read_states.has_key?(name)
          @read_states[name][args_json] = 'i'
          @remote_methods[name] = options unless @remote_methods.has_key?(name)
          @remote_methods[name][args_json] = { result: options[:default_result] } unless @remote_methods[name].has_key?(args_json)
          raise "#{self.class.to_s}[_no_id_].#{name}, can't execute instance remote_method without id!" unless self.id
          request = { 'hyperstack/handler/model/read' => { self.class.model_name => { instances: { id => { remote_methods: { name => { args => {}}}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            @remote_methods[name][args_json][:result]
          end.fail do |response|
            error_message = "#{self.class.to_s}[#{self.id}].#{name}, a remote_method, failed to execute!"
            `console.error(error_message)`
            response
          end
        end
        # @!method [name]
        # @return result either the default_result ass specified in the options or the real result if the RPC call already finished
        define_method(name) do |*args|
          unless self.id
            options[:default_result]
          else
            _register_observer
            args_json = args.to_json
            @remote_methods[name] = options unless @remote_methods.has_key?(name)
            @remote_methods[name][args_json] = { result: options[:default_result] } unless @remote_methods[name].has_key?(args_json)
            unless @read_states.has_key?(name) && @read_states[name].has_key?(args_json) && 'fi'.include?(@read_states[name][args_json])
              self.send("promise_#{name}", *args)
            end
            @remote_methods[name][args_json][:result]
          end
        end
        # @!method update_[name] mark internal structures so that the method is called again once it is requested again
        # @return nil
        define_method("update_#{name}") do
          @read_states[name] = 'u'
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
      def scope(name, _options = {})
        # @!method promise_[name]
        # @return [Promise] on success the .then block will receive a [Hyperstack::Record::Collection] as arg
        #     on failure the .fail block will receive some error indicator or nothing
        define_singleton_method("promise_#{name}") do |*args|
          args_json = args.to_json
          _class_read_states[name] = {} unless _class_read_states.has_key?(name)
          _class_read_states[name][args_json] = 'i'
          request = { 'hyperstack/handler/model/read' => { self.model_name => { scopes: { name => { args_json => {}}}}}}
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
            scopes[name][args_json]
          end.fail do |response|
            error_message = "#{self.to_s}.#{name}(#{args_json if args.any}), a scope, failed to read records!"
            `console.error(error_message)`
            response
          end
        end
        # @!method [name] get records of the scope
        # @return [Hyperstack::Record::Collection] either a empty one, if the data has not been readed yet, or the
        #   collection with the real data, if it has been readed already
        define_singleton_method(name) do |*args|
          args_json = args.to_json
          scopes[name] = {} unless scopes.has_key?(name)
          scopes[name][args_json] = Hyperstack::Record::Collection.new unless scopes.has_key?(name) && scopes[name].has_key?(args_json)
          _register_class_observer
          unless _class_read_states.has_key?(name) && _class_read_states[name].has_key?(args_json) && 'fi'.include?(_class_read_states[name][args_json])
            self.send("promise_#{name}", *args)
          end
          scopes[name][args_json]
        end
        # @!method update_[name] mark internal structures so that the scope data is updated once it is requested again
        # @return nil
        define_singleton_method("update_#{name}") do |*args|
          _class_read_states[name][args.to_json] = 'u'
          nil
        end
      end

      # introspect on available scopes
      # @return [Hash]
      def scopes
        @scopes ||= {}
      end

      # Find a collection of records by example properties.
      #
      # @param property_hash [Hash] properties with values used to identify wanted records
      #
      # @return [Promise] on success the .then block will receive a [Hyperstack::Record::Collection] as arg
      #     on failure the .fail block will receive some error indicator or nothing
      def promise_where(property_hash)
        agent = Hyperstack::Transport::RequestAgent.new
        request = { 'hyperstack/handler/model/read' => { self.model_name => { where: { agent.object_id => property_hash }}}}
        Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, request).then do
          raise if agent.errors
          agent.result
        end.fail do |response|
          error_message = "#{self.to_s}.where(#{property_hash} failed, #{agent.errors}!"
          `console.error(error_message)`
          response
        end
      end

      private
      # internal, should not be used in application code

      # @private
      def _class_read_states
        @_class_read_states ||= { all: { '[]' => 'n' }} # all is treated as scope
        @_class_read_states
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
end
