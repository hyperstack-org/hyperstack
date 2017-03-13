module Hyperloop
  # insure at least a stub of operation is defined.  If
  # Hyperloop::Operation is already loaded it will have
  # defined these.
  class Operation
    class << self
      def on_dispatch(&block)
        receivers << block
      end

      def receivers
        @receivers ||= []
      end
    end
  end unless defined? Operation
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
      rescue Exception => e
        puts "called Boot.run and she broke #{e}"
      end
    end unless defined? Boot
  end
end
