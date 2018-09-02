module Hyperloop
  class Operation
    class Railway

      def receivers
        self.class.receivers
      end

      class << self
        def receivers
          # use the force: true option so that system code needing to receive
          # boot will NOT be erased on the next Hyperloop::Context.reset!
          Hyperloop::Context.set_var(self, :@receivers, force: true) { [] }
        end

        def add_receiver(&block)
          receivers << block
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
