module Hyperstack
  module Internal
    module Component

      class PropsWrapper
        attr_reader :component

        def self.define_param(name, param_type)
          if param_type == Proc
            define_method("#{name}") do |*args, &block|
              props[name].call(*args, &block) if props[name]
            end
          else
            define_method("#{name}") do
              fetch_from_cache(name) do
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
            end
          end
        end

        def self.define_all_others(name)
          define_method("#{name}") do
            @_all_others_cache ||= yield(props)
          end
        end


        def initialize(component)
          @component = component
        end

        def [](prop)
          props[prop]
        end


        def _reset_all_others_cache
          @_all_others_cache = nil
        end

        private

        def fetch_from_cache(name)
          last, value = cache[name]
          return value if last.equal?(props[name])
          yield.tap do |value|
            cache[name] = [props[name], value]
          end
        end

        def cache
          @cache ||= Hash.new { |h, k| h[k] = [] }
        end

        def props
          component.props
        end

        def value_for(name)
          self[name].instance_variable_get("@value") if self[name]
        end
      end
    end
  end
end
