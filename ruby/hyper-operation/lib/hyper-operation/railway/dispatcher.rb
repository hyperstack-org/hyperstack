module Hyperstack
  class Operation
    class Railway

      def receivers
        self.class.receivers
      end

      class << self
        def receivers
          # use the force: true option so that system code needing to receive
          # boot will NOT be erased on the next Hyperstack::Context.reset!
          Hyperstack::Context.set_var(self, :@receivers, force: true) { [] }
        end

        def add_receiver(&block)
          cloned_block = ->(*args, &b) { block.call(*args, &b) }
          operation = self
          cloned_block.define_singleton_method(:unmount) { operation.receivers.delete(cloned_block) }
          receivers << cloned_block
          cloned_block
        end
      end

      def dispatch
        result.then do
          receivers.each do |receiver|
            receiver.call(
              self.class.params_wrapper.dispatch_params(@operation.params),
              @operation
            )
          end
        end
      end
    end
  end
end
