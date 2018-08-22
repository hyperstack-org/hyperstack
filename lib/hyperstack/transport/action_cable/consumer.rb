module Hyperstack
  module Transport
    module ActionCable
      class Consumer
        attr_reader :subscriptions

        def initialize(uri)
          @native_action_consumer = `ActionCable.createConsumer(uri)`
          @subscriptions = Hyperstack::Transport::ActionCable::Subscriptions.new(@native_action_consumer)
        end

        def connect
          @native_action_consumer.JS.connect
        end

        def disconnect
          @native_action_consumer.JS.disconnect
        end

        def send(data)
          @native_action_consumer.JS.send(data)
        end

      end
    end
  end
end