module Hyperlooop
  module Transport
    module ActionCable
      class Subscriptions
        def initialize(native_action_consumer)
          @native_action_consumer = native_action_consumer
        end

        def create(channel_options)
          native_subscription = @native_action_consumer.JS.subscriptions.JS.create(channel_options.to_n)
          Hyperloop::Transport::ActionCable::Subscription.new(native_subscription)
        end
      end
    end
  end
end
