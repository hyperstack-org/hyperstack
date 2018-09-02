module Hyperloop
  # insure at least a stub of operation is defined.  If
  # Hyperloop::Operation is already loaded it will have
  # defined these.
  class Operation
    class << self
      def on_dispatch(&block)
        receivers << block
      end unless method_defined? :on_dispatch

      def receivers
        # use the force: true option so that system code needing to receive
        # boot will NOT be erased on the next Hyperloop::Context.reset!
        Hyperloop::Context.set_var(self, :@receivers, force: true) { [] }
      end unless method_defined? :receivers
    end
  end
  class Application
    class Boot < Operation
      class ReactDummyParams
        attr_reader :context
        def initialize(context)
          @context = context
        end
      end
      def self.run(context: nil)
        params = ReactDummyParams.new(context)
        receivers.each do |receiver|
          receiver.call params
        end
      end
    end unless defined? Boot
  end
end
