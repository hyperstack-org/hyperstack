module Hyperloop
# configuration utility
  class << self
    def initialized_blocks
      @initialized_blocks ||= []
    end

    def reset_blocks
      @reset_blocks ||= []
    end

    def configuration
      reset_blocks.each(&:call)
      yield self
      initialized_blocks.each(&:call)
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


    def on_config_reset &block
      reset_blocks << block
    end

    def on_config_initialized &block
      initialized_blocks << block
    end

    private

    def define_class_method(name, &block)
      (class << self; self; end).instance_eval do
        define_method name, &block
      end
    end
  end
end
