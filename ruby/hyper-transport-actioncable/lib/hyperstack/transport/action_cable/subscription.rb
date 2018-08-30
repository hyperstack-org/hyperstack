module Hyperstack
  module Transport
    module ActionCable
      class Subscription
        def initialize(native_subscription)
          @native_subscription = native_subscription
        end

        def perform(action, data)
          @native_subscription.JS.perform(action, data)
        end

        def send(data)
          @native_subscription.JS.send(data)
        end

        def unsubscribe
          @native_subscription.JS.unsubscribe
        end
      end
    end
  end
end
