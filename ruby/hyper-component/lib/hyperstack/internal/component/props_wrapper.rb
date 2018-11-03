module Hyperstack
  module Internal
    module Component
      class PropsWrapper
        attr_reader :component

        def self.param_definitions
          @param_definitions ||=
            if superclass.respond_to? :param_definitions
              superclass.param_definitions.dup
            else
              Hash.new
            end
        end

        def self.define_param(name, param_type, aka = nil)
          aka ||= name
          param_definitions[name] = ->(props) { @component.instance_variable_set :"@#{aka}", fetch_from_cache(name, param_type, props) } #[param_type, aka || name]
          if param_type == Proc
            define_method(aka.to_sym) do |*args, &block|
              props[name].call(*args, &block) if props[name]
            end
          else
            define_method(aka.to_sym) do
              fetch_from_cache(name, param_type, props)
            end
          end
        end

        def self.define_all_others(name)
          param_definitions[name] = -> (props) { puts "setting @#{name} props = #{props} self = #{self}"; @component.instance_variable_set :"@#{name}", yield(props) } #[:__hyperstack_component_all_others_flag, name, block]
          define_method(name.to_sym) do
            puts "calling good ole params.#{name} props = #{props} self = #{self}"
            @_all_others_cache ||= yield(props)
          end
        end

        def initialize(component, incoming = nil)
          @component = component
          self.class.param_definitions.each_value do |initializer|
            instance_exec(incoming || props, &initializer)
          end
        end

        def reload(next_props)
          initialize(@component, next_props)
        end

        def [](prop)
          props[prop]
        end

        def _reset_all_others_cache
          @_all_others_cache = nil
        end

        private

        def fetch_from_cache(name, param_type, props)
          last, cached_value = cache[name]
          return cached_value if last.equal?(props[name])
          convert_param(name, param_type).tap do |value|
            cache[name] = [props[name], value]
          end
        end

        def convert_param(name, param_type)
          if param_type.respond_to? :_react_param_conversion
            param_type._react_param_conversion props[name], nil
          elsif param_type.is_a?(Array) &&
                param_type[0].respond_to?(:_react_param_conversion)
            props[name].collect do |param|
              param_type[0]._react_param_conversion param, nil
            end
          else
            props[name]
          end
        end

        def cache
          @cache ||= Hash.new { |h, k| h[k] = [] }
        end

        def props
          component.props
        end

        def value_for(name)
          self[name].instance_variable_get('@value') if self[name]
        end
      end
    end
  end
end
