module HyperRecord
  module ClassMethods

    def new(record_hash = {})
      if record_hash.has_key?(:id)
        record = _record_cache[record_hash[:id].to_s]
        if record
          record.instance_variable_get(:@properties).merge!(record_hash)
          return record
        end
      end
      super(record_hash)
    end

    def all
      _register_class_observer
      if _class_fetch_states.has_key?(:all) && 'fi'.include?(_class_fetch_states[:all]) # if f_etched or i_n progress of fetching
        collection = HyperRecord::Collection.new
        _record_cache.each_value { |record| collection.push(record) }
        return collection
      end
      promise_all
      HyperRecord::Collection.new
    end

    def promise_all
      _class_fetch_states[:all] = 'i'
      _promise_get("#{resource_base_uri}.json?timestamp=#{`Date.now() + Math.random()`}").then do |response|
        collection = _convert_array_to_collection(response.json[self.to_s.underscore.pluralize])
        _class_fetch_states[:all] = 'f'
        _notify_class_observers
        collection
      end.fail do |response|
        error_message = "#{self.to_s}.all failed to fetch records!"
        `console.error(error_message)`
        response
      end
    end

    def belongs_to(direction, name = nil, options = { type: nil })
      if name.is_a?(Hash)
        options.merge(name)
        name = direction
        direction = nil
      elsif name.is_a?(Proc)
        name = direction
        direction = nil
      elsif name.nil?
        name = direction
      end
      reflections[name] = { direction: direction, type: options[:type], kind: :belongs_to }
      define_method("promise_#{name}") do
        @fetch_states[name] = 'i'
        self.class._promise_get("#{self.class.resource_base_uri}/#{self.id}/relations/#{name}.json?timestamp=#{`Date.now() + Math.random()`}").then do |response|
          @relations[name] = self.class._convert_json_hash_to_record(response.json[self.class.to_s.underscore][name])
          @fetch_states[name] = 'f'
          _notify_observers
          @relations[name]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{name}, a belongs_to association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      define_method(name) do
        _register_observer
        if @fetch_states.has_key?(name) && 'fi'.include?(@fetch_states[name])
          @relations[name]
        elsif self.id
          send("promise_#{name}")
          @relations[name]
        else
          @relations[name]
        end
      end
      define_method("update_#{name}") do
        @fetch_states[name] = 'u'
      end
      # TODO
      # define_method("#{name}=") do |arg|
      #   _register_observer
      #   @relations[name] = arg
      #   @fetch_states[name] = 'f'
      #   @relations[name]
      # end
    end

    def create(record_hash = {})
      record = new(record_hash)
      record.save
    end

    def promise_create(record_hash = {})
      record = new(record_hash)
      record.promise_save
    end

    def find(id)
      sid = id.to_s
      return _record_cache[sid] if _record_cache.has_key?(sid) && _class_fetch_states["record_#{id}"] == 'f'
      observer = React::State.current_observer
      record_in_progress = if _record_cache.has_key?(sid)
                             _record_cache[sid]
                           else
                             self.new(id: id)
                           end
      record_in_progress_key = "#{self.to_s}_#{record_in_progress.object_id}"
      React::State.get_state(observer, record_in_progress_key) if observer
      return _record_cache[sid] if _record_cache.has_key?(sid) && _class_fetch_states["record_#{id}"] == 'i'
      _promise_find(id, record_in_progress).then do
        React::State.set_state(observer, record_in_progress_key, `Date.now() + Math.random()`) if observer
      end
      record_in_progress
    end

    def promise_find(id)
      sid = id.to_s
      record_in_progress = if _record_cache.has_key?(sid)
                             _record_cache[sid]
                           else
                             self.new(id: id)
                           end
      _promise_find(id, record_in_progress)
    end

    # TODO find_by
    # def promise_find_by(hash)
    #   if hash.has_key?[:id] && _record_cache.has_key?(hash[:id].to_s)
    #     record = _record_cache[hash[:id].to_s]
    #     found = true
    #     hash.each do |k,v|
    #       if record.send(k) != v
    #         found = false
    #         break
    #       end
    #     end
    #     return record if found
    #   end
    #   # TODO needs clarification about how to call the endpoint
    #   _promise_get("#{resource_base_uri}/#{id}.json").then do |response|
    #     self.new(response.json[self.to_s.underscore])
    #   end
    # end

    def has_and_belongs_to_many(direction, name = nil, options = { type: nil })
      if name.is_a?(Hash)
        options.merge(name)
        name = direction
        direction = nil
      elsif name.is_a?(Proc)
        name = direction
        direction = nil
      elsif name.nil?
        name = direction
      end
      reflections[name] = { direction: direction, type: options[:type], kind: :has_and_belongs_to_many }
      define_method("promise_#{name}") do
        @fetch_states[name] = 'i'
        self.class._promise_get("#{self.class.resource_base_uri}/#{self.id}/relations/#{name}.json?timestamp=#{`Date.now() + Math.random()`}").then do |response|
          collection = self.class._convert_array_to_collection(response.json[self.class.to_s.underscore][name], self, name)
          @relations[name] = collection
          @fetch_states[name] = 'f'
          _notify_observers
          @relations[name]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{name}, a has_and_belongs_to_many association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      define_method(name) do
        _register_observer
        if @fetch_states.has_key?(name) && 'fi'.include?(@fetch_states[name])
          @relations[name]
        elsif self.id
          send("promise_#{name}")
          @relations[name]
        else
          @relations[name]
        end
      end
      define_method("update_#{name}") do
        @fetch_states[name] = 'u'
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

    def has_many(direction, name = nil, options = { type: nil })
      if name.is_a?(Hash)
        options.merge(name)
        name = direction
        direction = nil
      elsif name.is_a?(Proc)
        name = direction
        direction = nil
      elsif name.nil?
        name = direction
      end
      reflections[name] = { direction: direction, type: options[:type], kind: :has_many }
      define_method("promise_#{name}") do
        @fetch_states[name] = 'i'
        self.class._promise_get("#{self.class.resource_base_uri}/#{self.id}/relations/#{name}.json?timestamp=#{`Date.now() + Math.random()`}").then do |response|
          collection = self.class._convert_array_to_collection(response.json[self.class.to_s.underscore][name], self, name)
          @relations[name] = collection
          @fetch_states[name] = 'f'
          _notify_observers
          @relations[name]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{name}, a has_many association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      define_method(name) do
        _register_observer
        if @fetch_states.has_key?(name) && 'fi'.include?(@fetch_states[name])
          @relations[name]
        elsif self.id
          send("promise_#{name}")
          @relations[name]
        else
          @relations[name]
        end
      end
      define_method("update_#{name}") do
        @fetch_states[name] = 'u'
      end
      # define_method("#{name}=") do |arg|
      #   _register_observer
      #   collection = if arg.is_a?(Array)
      #     HyperRecord::Collection.new(arg, self, name)
      #   elsif arg.is_a?(HyperRecord::Collection)
      #     arg
      #   else
      #     raise "Argument must be a HyperRecord::Collection or a Array"
      #   end
      #   @relations[name] = collection
      #   @fetch_states[name] = 'f'
      #   @relations[name]
      # end
    end

    def has_one(direction, name, options = { type: nil })
      if name.is_a?(Hash)
        options.merge(name)
        name = direction
        direction = nil
      elsif name.is_a?(Proc)
        name = direction
        direction = nil
      elsif name.nil?
        name = direction
      end
      reflections[name] = { direction: direction, type: options[:type], kind: :has_one }
      define_method("promise_#{name}") do
        @fetch_states[name] = 'i'
        self.class._promise_get("#{self.class.resource_base_uri}/#{self.id}/relations/#{name}.json?timestamp=#{`Date.now() + Math.random()`}").then do |response|
          @relations[name] = self.class._convert_json_hash_to_record(response.json[self.class.to_s.underscore][name])
          @fetch_states[name] = 'f'
          _notify_observers
          @relations[name]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{name}, a has_one association, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      define_method(name) do
        _register_observer
        if @fetch_states.has_key?(name) && 'fi'.include?(@fetch_states[name])
          @relations[name]
        elsif self.id
          send("promise_#{name}")
          @relations[name]
        else
          @relations[name]
        end
      end
      define_method("update_#{name}") do
        @fetch_states[name] = 'u'
      end
      # define_method("#{name}=") do |arg|
      #   _register_observer
      #   @relations[name] = arg
      #   @fetch_states[name] = 'f'
      #   @relations[name]
      # end
    end

    def record_cached?(id)
      _record_cache.has_key?(id.to_s)
    end

    def property(name, options = {})
      # ToDo options maybe, ddefault value? type check?
      _property_options[name] = options
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
      define_method("#{name}=") do |value|
        _register_observer
        @changed_properties[name] = value
      end
    end

    def reflections
      @reflections ||= {}
    end

    def rest_class_method(name, options = { default_result: '...' })
      rest_class_methods[name] = options
      define_singleton_method("promise_#{name}") do |*args|
        name_args = _name_args(name, *args)
        _class_fetch_states[name_args] = 'i'
        rest_class_methods[name_args] = { result: options[:default_result] } unless rest_class_methods.has_key?(name_args)
        _promise_get_or_patch("#{resource_base_uri}/methods/#{name}.json?timestamp=#{`Date.now() + Math.random()`}", *args).then do |response_json|
          rest_class_methods[name_args][:result] = response_json[:result] # result is parsed json
          _class_fetch_states[name_args] = 'f'
          _notify_class_observers
          rest_class_methods[name_args][:result]
        end.fail do |response|
          error_message = "#{self.to_s}.#{name}, a rest_method, failed to execute!"
          `console.error(error_message)`
          response
        end
      end
      define_singleton_method(name) do |*args|
        name_args = _name_args(name, *args)
        _register_class_observer
        rest_class_methods[name_args] = { result: options[:default_result] } unless rest_methods.has_key?(name_args)
        unless _class_fetch_states.has_key?(name_args) && 'fi'.include?(_class_fetch_states[name_args])
          self.send("promise_#{name}", *args)
        end
        rest_class_methods[name_args][:result]
      end
      define_singleton_method("update_#{name}") do |*args|
        _class_fetch_states[_name_args(name, *args)] = 'u'
      end
    end

    def rest_method(name, options = { default_result: '...' })
      define_method("promise_#{name}") do |*args|
        name_args = self.class._name_args(name, *args)
        @fetch_states[name_args] = 'i'
        @rest_methods[name] = options unless @rest_methods.has_key?(name)
        @rest_methods[name_args] = { result: options[:default_result] } unless @rest_methods.has_key?(name_args)
        raise "#{self.class.to_s}[_no_id_].#{name}, can't execute instance rest_method without id!" unless self.id
        self.class._promise_get_or_patch("#{resource_base_uri}/#{self.id}/methods/#{name}.json?timestamp=#{`Date.now() + Math.random()`}", *args).then do |response_json|
          @rest_methods[name_args][:result] = response_json[:result] # result is parsed json
          @fetch_states[name_args] = 'f'
          _notify_observers
          @rest_methods[name_args][:result]
        end.fail do |response|
          error_message = "#{self.class.to_s}[#{self.id}].#{name}, a rest_method, failed to execute!"
          `console.error(error_message)`
          response
        end
      end
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
      define_method("update_#{name}") do |*args|
        @fetch_states[self.class._name_args(name, *args)] = 'u'
      end
    end

    def rest_class_methods
      @rest_class_methods ||= {}
    end

    def resource_base_uri
      @resource ||= "#{Hyperloop::Resource::ClientDrivers.opts[:resource_api_base_path]}/#{self.to_s.underscore.pluralize}"
    end

    def scope(name, options)
      define_singleton_method("promise_#{name}") do |*args|
        name_args = _name_args(name, *args)
        _class_fetch_states[name_args] = 'i'
        self._promise_get_or_patch("#{resource_base_uri}/scopes/#{name}.json?timestamp=#{`Date.now() + Math.random()`}", *args).then do |response_json|
          scopes[name_args] = _convert_array_to_collection(response_json[self.to_s.underscore][name])
          _class_fetch_states[name_args] = 'f'
          _notify_class_observers
          scopes[name_args]
        end.fail do |response|
          error_message = "#{self.to_s}.#{name_args}, a scope, failed to fetch records!"
          `console.error(error_message)`
          response
        end
      end
      define_singleton_method(name) do |*args|
        name_args = _name_args(name, *args)
        scopes[name_args] = HyperRecord::Collection.new unless scopes.has_key?(name_args)
        _register_class_observer
        unless _class_fetch_states.has_key?(name_args) && 'fi'.include?(_class_fetch_states[name_args])
          self.send("promise_#{name}", *args)
        end
        scopes[name_args]
      end
      define_singleton_method("update_#{name}") do |*args|
        _class_fetch_states[_name_args(name, *args)] = 'u'
      end
    end

    def scopes
      @scopes ||= {}
    end

    ### internal

    def _convert_array_to_collection(array, record = nil, relation_name = nil)
      res = array.map do |record_hash|
        _convert_json_hash_to_record(record_hash)
      end
      HyperRecord::Collection.new(res, record, relation_name)
    end

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
        record
      end
    end

    def _class_fetch_states
      @_class_fetch_states ||= { all: 'n' }
      @_class_fetch_states
    end

    def _class_observers
      @_class_observers ||= Set.new
      @_class_observers
    end

    def _class_state_key
      @_class_state_key ||= self.to_s
      @_class_state_key
    end

    def _name_args(name, *args)
      if args.size > 0
        "#{name}_#{args.to_json}"
      else
        name
      end
    end

    def _promise_find(id, record_in_progress)
      _class_fetch_states["record_#{id}"] = 'i'
      _promise_get("#{resource_base_uri}/#{id}.json").then do |response|
        klass_key = self.to_s.underscore
        # optimization for fetching relations with records
        # reflections.keys.each do |relation|
        #   if response.json[klass_key].has_key?(relation)
        #     response.json[klass_key][r_or_s] = _convert_array_to_collection(response.json[klass_key][relation])
        #     record_in_progress.instance_variable_get(:@fetch_states)[relation] = 'f'
        #   end
        # end
        record_in_progress._initialize_from_hash(response.json[klass_key]) if response.json[klass_key]
        _class_fetch_states["record_#{id}"] = 'f'
        record_in_progress
      end.fail do |response|
        error_message = "#{self.to_s}.find(#{id}) failed to fetch record!"
        `console.error(error_message)`
        response
      end
    end

    def _notify_class_observers
      _class_observers.each do |observer|
        React::State.set_state(observer, _class_state_key, `Date.now() + Math.random()`)
      end
      _class_observers = Set.new
    end

    def _promise_get(uri)
      Hyperloop::Resource::HTTP.get(uri, headers: { 'Content-Type' => 'application/json' })
    end

    def _promise_get_or_patch(uri, *args)
      if args && args.size > 0
        payload = { params: args }
        _promise_patch(uri, payload).then do |response|
          response.json
        end
      else
        _promise_get(uri).then do |response|
          response.json
        end
      end
    end

    def _promise_delete(uri)
      Hyperloop::Resource::HTTP.delete(uri, headers: { 'Content-Type' => 'application/json' })
    end

    def _promise_patch(uri, payload)
      Hyperloop::Resource::HTTP.patch(uri, payload: payload,
                                 headers: { 'Content-Type' => 'application/json' },
                                 dataType: :json)
    end

    def _promise_post(uri, payload)
      Hyperloop::Resource::HTTP.post(uri, payload: payload,
                                headers: { 'Content-Type' => 'application/json' },
                                dataType: :json)
    end

    def _property_options
      @property_options ||= {}
    end

    def _record_cache
      @record_cache ||= {}
    end

    def _register_class_observer
      observer = React::State.current_observer
      if observer
        React::State.get_state(observer, _class_state_key)
        _class_observers << observer # @observers is a set, observers get added only once
      end
    end
  end

end
