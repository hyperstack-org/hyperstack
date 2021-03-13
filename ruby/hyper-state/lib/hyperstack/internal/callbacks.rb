module Hyperstack
  module Internal
    module Callbacks
      if RUBY_ENGINE != 'opal'
        class Hyperstack::Hotloader
          def self.when_file_updates(&block); end
        end
      end
      def self.included(base)
        base.extend(ClassMethods)
      end

      def run_callback(name, *args)
        self.class.callbacks_for(name).flatten.each do |callback|
          callback = method(callback) unless callback.is_a? Proc
          args = self.class.send("_#{name}_before_call_hook", name, self, callback, *args)
        end
        args
      end

      module ClassMethods
        def define_callback(callback_name, before_call_hook: nil, after_define_hook: nil)
          wrapper_name = "_#{callback_name}_callbacks"
          define_singleton_method(wrapper_name) do
            Context.set_var(self, "@#{wrapper_name}", force: true) { [] }
          end
          before_call_hook ||= lambda do |_name, sself, proc, *args|
            sself.instance_exec(*args, &proc)
            args
          end
          define_singleton_method("_#{callback_name}_before_call_hook", &before_call_hook)
          define_singleton_method(callback_name) do |*args, &block|
            args << block if block_given?
            send(wrapper_name).push args
            Hotloader.when_file_updates do
              send(wrapper_name).delete_if { |item| item.equal? args }
            end
            after_define_hook.call(self) if after_define_hook
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

        def callbacks?(name)
          callbacks_for(name).any?
        end
      end
    end
  end
end
