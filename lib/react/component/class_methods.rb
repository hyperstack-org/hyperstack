module React
  module Component
    # class level methods (macros) for components
    module ClassMethods

      def reactrb_component?
        true
      end

      def backtrace(*args)
        @dont_catch_exceptions = (args[0] == :none)
        @backtrace_off = @dont_catch_exceptions || (args[0] == :off)
      end

      def process_exception(e, component, reraise = @dont_catch_exceptions)
        unless @dont_catch_exceptions
          message = ["Exception raised while rendering #{component}: #{e.message}"]
          if e.backtrace && e.backtrace.length > 1 && !@backtrace_off
            append_backtrace(message, e.backtrace)
          end
          `console.error(#{message.join("\n")})`
        end
        raise e if reraise
      end

      def append_backtrace(message_array, backtrace)
        message_array << "    #{backtrace[0]}"
        backtrace[1..-1].each { |line| message_array << line }
      end

      def render(container = nil, params = {}, &block)
        if container
          container = container.type if container.is_a? React::Element
          define_method :render do
            React::RenderingContext.render(container, params) { instance_eval(&block) if block }
          end
        else
          define_method(:render) { instance_eval(&block) }
        end
      end

      # method missing will assume the method is a class name, and will treat this a render of
      # of the component, i.e. Foo::Bar.baz === Foo::Bar().baz

      def method_missing(name, *args, &children)
        Object.method_missing(name, *args, &children) unless args.empty?
        React::RenderingContext.render(
          self, class: React::Element.haml_class_name(name), &children
        )
      end

      def validator
        @validator ||= Validator.new(props_wrapper)
      end

      def prop_types
        if self.validator
          {
            _componentValidator: %x{
              function(props, propName, componentName) {
                var errors = #{validator.validate(Hash.new(`props`))};
                var error = new Error(#{"In component `#{name}`\n" + `errors`.join("\n")});
                return #{`errors`.count > 0 ? `error` : `undefined`};
              }
            }
          }
        else
          {}
        end
      end

      def default_props
        validator.default_props
      end

      def params(&block)
        validator.build(&block)
      end

      def props_wrapper
        @props_wrapper ||= Class.new(PropsWrapper)
      end

      def param(*args)
        if args[0].is_a? Hash
          options = args[0]
          name = options.first[0]
          default = options.first[1]
          options.delete(name)
          options.merge!({default: default})
        else
          name = args[0]
          options = args[1] || {}
        end
        if options[:default]
          validator.optional(name, options)
        else
          validator.requires(name, options)
        end
      end

      def collect_other_params_as(name)
        validator.allow_undefined_props = true
        validator_in_lexical_scope = validator
        props_wrapper.define_method(name) do
          @_all_others ||= validator_in_lexical_scope.undefined_props(props)
        end

        validator_in_lexial_scope = validator
        props_wrapper.define_method(name) do
          @_all_others ||= validator_in_lexial_scope.undefined_props(props)
        end
      end

      def define_state(*states, &block)
        default_initial_value = (block && block.arity == 0) ? yield : nil
        states_hash = (states.last.is_a?(Hash)) ? states.pop : {}
        states.each { |name| states_hash[name] = default_initial_value }
        (self.initial_state ||= {}).merge! states_hash
        states_hash.each do |name, initial_value|
          define_state_methods(self, name, &block)
        end
      end

      def export_state(*states, &block)
        default_initial_value = (block && block.arity == 0) ? yield : nil
        states_hash = (states.last.is_a?(Hash)) ? states.pop : {}
        states.each { |name| states_hash[name] = default_initial_value }
        State.initialize_states(self, states_hash)
        states_hash.each do |name, initial_value|
          define_state_methods(self, name, self, &block)
          define_state_methods(singleton_class, name, self, &block)
        end
      end

      def define_state_methods(this, name, from = nil, &block)
        this.define_method("#{name}") do
          React::Component.deprecation_warning "Direct access to state `#{name}`.  Use `state.#{name}` instead." if from.nil? || from == this
          State.get_state(from || self, name)
        end
        this.define_method("#{name}=") do |new_state|
          React::Component.deprecation_warning "Direct assignment to state `#{name}`.  Use `#{(from && from != this) ? from : 'state'}.#{name}!` instead."
          yield name, State.get_state(from || self, name), new_state if block && block.arity > 0
          State.set_state(from || self, name, new_state)
        end
        this.define_method("#{name}!") do |*args|
          React::Component.deprecation_warning "Direct access to state `#{name}`.  Use `state.#{name}` instead."  if from.nil? or from == this
          if args.count > 0
            yield name, State.get_state(from || self, name), args[0] if block && block.arity > 0
            current_value = State.get_state(from || self, name)
            State.set_state(from || self, name, args[0])
            current_value
          else
            current_state = State.get_state(from || self, name)
            yield name, State.get_state(from || self, name), current_state if block && block.arity > 0
            State.set_state(from || self, name, current_state)
            Observable.new(current_state) do |update|
              yield name, State.get_state(from || self, name), update if block && block.arity > 0
              State.set_state(from || self, name, update)
            end
          end
        end
      end

      def native_mixin(item)
        native_mixins << item
      end

      def native_mixins
        @native_mixins ||= []
      end

      def static_call_back(name, &block)
        static_call_backs[name] = block
      end

      def static_call_backs
        @static_call_backs ||= {}
      end

      def export_component(opts = {})
        export_name = (opts[:as] || name).split('::')
        first_name = export_name.first
        Native(`window`)[first_name] = add_item_to_tree(
          Native(`window`)[first_name],
          [React::API.create_native_react_class(self)] + export_name[1..-1].reverse
        ).to_n
      end

      def imports(component_name)
        React::API.import_native_component(
          self, React::API.eval_native_react_component(component_name)
        )
        define_method(:render) {} # define a dummy render method - will never be called...
      rescue Exception => e # rubocop:disable Lint/RescueException : we need to catch everything!
        raise "#{self} cannot import '#{component_name}': #{e.message}."
        # rubocop:enable Lint/RescueException
      ensure
        self
      end

      def add_item_to_tree(current_tree, new_item)
        if Native(current_tree).class != Native::Object || new_item.length == 1
          new_item.inject { |a, e| { e => a } }
        else
          Native(current_tree)[new_item.last] = add_item_to_tree(
            Native(current_tree)[new_item.last], new_item[0..-2]
          )
          current_tree
        end
      end
    end
  end
end
