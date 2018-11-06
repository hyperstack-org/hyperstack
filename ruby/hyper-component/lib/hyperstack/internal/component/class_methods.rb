module Hyperstack
  module Internal
    module Component
      # class level methods (macros) for components
      module ClassMethods

        def deprecation_warning(message)
          Hyperstack.deprecation_warning(self, message)
        end

        def hyper_component?
          true
        end

        def param_accessor_style(*args)
          props_wrapper.param_accessor_style(*args)
        end

        def backtrace(*args)
          @__hyperstack_component_dont_catch_exceptions = (args[0] == :none)
          @__hyperstack_component_backtrace_off = @__hyperstack_component_dont_catch_exceptions || (args[0] == :off)
        end

        def append_backtrace(message_array, backtrace)
          message_array << "    #{backtrace[0]}"
          backtrace[1..-1].each { |line| message_array << line }
        end

        def render(container = nil, params = {}, &block)
          if container
            container = container.type if container.is_a? Hyperstack::Component::Element
            define_method :render do
              RenderingContext.render(container, params) { instance_eval(&block) if block }
            end
          else
            define_method(:render) { instance_eval(&block) }
          end
        end

        # method missing will assume the method is a class name, and will treat this a render of
        # of the component, i.e. Foo::Bar.baz === Foo::Bar().baz

        def method_missing(name, *args, &children)
          if args.any? || !Hyperstack::Component::Element.respond_to?(:haml_class_name)
            super
          # this was:
          #   Object.method_missing(name, *args, &children) unless args.empty?
          # Which does not show the actual component that broke.
          # Not sure why this was like this, in tags.rb there is a similar method
          # missing that calls Object._reactrb_import_component_class(name) which
          # makes sure to autoimport the component.  This is not needed here, as
          # we already have the class.
          else
            RenderingContext.render(
              self, class: Hyperstack::Component::Element.haml_class_name(name), &children
            )
          end
        end

        def validator
          return @__hyperstack_component_validator if @__hyperstack_component_validator
          if superclass.respond_to?(:validator)
            @__hyperstack_component_validator = superclass.validator.copy(props_wrapper)
          else
            @__hyperstack_component_validator = Validator.new(props_wrapper)
          end
        end

        def prop_types
          if self.validator
            {
              _componentValidator: %x{
                function(props, propName, componentName) {
                  var errors = #{validator.validate(Hash.new(`props`))};
                  return #{`errors`.count > 0 ? `new Error(#{"In component `#{name}`\n" + `errors`.join("\n")})` : `undefined`};
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
          return @__hyperstack_component_props_wrapper if @__hyperstack_component_props_wrapper
          if superclass.respond_to? :props_wrapper
            @__hyperstack_component_props_wrapper = Class.new(superclass.props_wrapper)
          else
            @__hyperstack_component_props_wrapper ||= Class.new(PropsWrapper)
          end
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
          if options[:type] == Proc
            options[:default] ||= nil
            options[:allow_nil] = true unless options.key?(:allow_nil)
          end
          if options[:default]
            validator.optional(name, options)
          else
            validator.requires(name, options)
          end
        end

        def collect_other_params_as(name)
          validator.all_other_params(name) { props }
        end

        alias other_params collect_other_params_as
        alias others collect_other_params_as

        def raises(name, opts = {})
          aka = opts[:alias] || "#{name}!"
          name = name =~ /^<(.+)>$/ ? name.gsub(/^<(.+)>$/, '\1') : "on_#{name}"
          validator.event(name)
          define_method(aka) { |*args| props[name]&.call(*args) }
        end

        def define_state(*states, &block)
          deprecation_warning "'define_state' is deprecated. Use the 'state' macro to declare states."
          default_initial_value = (block && block.arity == 0) ? yield : nil
          states_hash = (states.last.is_a?(Hash)) ? states.pop : {}
          states.each { |name| state(name => default_initial_value) } # was states_hash[name] = default_initial_value
          states_hash.each { |name, value| state(name => value) }
        end

        def export_state(*states, &block)
          deprecation_warning "'export_state' is deprecated. Use the 'state' macro to declare states."
          default_initial_value = (block && block.arity == 0) ? yield : nil
          states_hash = (states.last.is_a?(Hash)) ? states.pop : {}
          states.each { |name| states_hash[name] = default_initial_value }
          states_hash.each do |name, value|
            state(name => value, scope: :class, reader: true)
            singleton_class.define_method("#{name}!") do |*args|
              mutate.__send__(name, *args)
            end
          end
        end

        def native_mixin(item)
          native_mixins << item
        end

        def native_mixins
          @__hyperstack_component_native_mixins ||= []
        end

        def static_call_back(name, &block)
          static_call_backs[name] = block
        end

        def static_call_backs
          @__hyperstack_component_static_call_backs ||= {}
        end

        def export_component(opts = {})
          export_name = (opts[:as] || name).split('::')
          first_name = export_name.first
          Native(`Opal.global`)[first_name] = add_item_to_tree(
            Native(`Opal.global`)[first_name],
            [ReactWrapper.create_native_react_class(self)] + export_name[1..-1].reverse
          ).to_n
        end

        def imports(component_name)
          ReactWrapper.import_native_component(
            self, ReactWrapper.eval_native_react_component(component_name)
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

        def to_n
          ReactWrapper.class_eval('@@component_classes')[self]
        end
      end
    end
  end
end
