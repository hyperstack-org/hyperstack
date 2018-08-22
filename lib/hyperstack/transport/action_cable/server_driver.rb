module Hyperstack
  module Transport
    module ActionCable
      class ServerDriver
        def self.pusher_instance
          @pusher_instance ||= ::Pusher::Client.new(Hyperstack.pusher_server_options)
        end

        def self.publish(channels, message)
          pusher_instance.trigger_async(channels, 'update', message)
        end
      end
    end
  end
end