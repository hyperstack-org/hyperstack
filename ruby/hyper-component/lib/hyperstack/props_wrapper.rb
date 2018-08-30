module Hyperstack
  class PropsWrapper
    attr_reader :instance_with_props

    def self.define_param(name, param_type)
      if RUBY_ENGINE == 'opal'
        if param_type == ::React::Observable
          define_method("#{name}") do
            value_for(name)
          end
          define_method("#{name}!") do |*args|
            current_value = value_for(name)
            if args.count > 0
              props[name].call args[0]
              current_value
            else
              props[name]
            end
          end
        elsif param_type == Proc
          define_method("#{name}") do |*args, &block|
            props[name].call(*args, &block) if props[name]
          end
        else
          define_method("#{name}") do
            props[name]
          end
        end
      else
        if param_type == Proc
          define_method("#{name}") do |*args, &block|
            props[name].call(*args, &block) if props[name]
          end
        else
          define_method("#{name}") do
            props[name]
          end
        end
      end
    end

    def initialize(instance_with_props)
      @instance_with_props = instance_with_props
    end

    def [](prop)
      props[prop]
    end

    private

    def props
      instance_with_props.props
    end

    def value_for(name)
      self[name].instance_variable_get("@value") if self[name]
    end
  end
end
