require 'hyperloop-config'

module React
  module Callbacks
    def self.included(base)
      base.extend(ClassMethods)
    end

    def run_callback(name, *args)
      self.class.callbacks_for(name).each do |callback|
        if callback.is_a?(Proc)
          instance_exec(*args, &callback)
        else
          send(callback, *args)
        end
      end
    end

    module ClassMethods
      def define_callback(callback_name)
        wrapper_name = "_#{callback_name}_callbacks"
        define_singleton_method(wrapper_name) do
          Hyperloop::Context.set_var(self, "@#{wrapper_name}", force: true) { [] }
        end
        define_singleton_method(callback_name) do |*args, &block|
          send(wrapper_name).concat(args)
          send(wrapper_name).push(block) if block_given?
        end
      end

      def callbacks_for(callback_name)
        wrapper_name = "_#{callback_name}_callbacks"
        if superclass.respond_to? :callbacks_for
          superclass.callbacks_for(callback_name)
        else
          []
        end + send(wrapper_name)
      end
    end
  end
end
