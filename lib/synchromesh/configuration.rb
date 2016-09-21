module Synchromesh
  # configuration utility
  module Configuration

    def configuration
      config_reset
      yield self
      config_initialized
    end

    def define_setting(name, default = nil, &block)
      class_variable_set("@@#{name}", default)

      define_class_method "#{name}=" do |value|
        class_variable_set("@@#{name}", value)
        block.call value if block
        value
      end

      define_class_method name do
        class_variable_get("@@#{name}")
      end
    end

    def config_reset
      raise "must implement"
    end

    def config_initialized
    end

    private

    def define_class_method(name, &block)
      (class << self; self; end).instance_eval do
        define_method name, &block
      end
    end
  end
end
