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
          result = if callback.is_a?(Proc)
                     instance_exec(*args, &callback)
                   else
                     send(callback, *args)
                   end
          args = yield(result) if block_given?
        end
        args
      end

      module ClassMethods
        def define_callback(callback_name, &after_define_hook)
          wrapper_name = "_#{callback_name}_callbacks"
          define_singleton_method(wrapper_name) do
            Context.set_var(self, "@#{wrapper_name}", force: true) { [] }
          end
          define_singleton_method(callback_name) do |*args, &block|
            args << block if block_given?
            send(wrapper_name).push args
            Hotloader.when_file_updates do
              send(wrapper_name).delete_if { |item| item.equal? args }
            end
            after_define_hook.call(*args, &block) if after_define_hook
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
