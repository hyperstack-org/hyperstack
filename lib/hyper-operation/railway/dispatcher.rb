module Hyperloop
  class Operation
    class Railway

      def receivers
        self.class.receivers
      end

      class << self
        def receivers
          @receivers ||= []
        end

        def add_receiver(block)
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
