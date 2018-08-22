module Hyperstack
  module Transport
    module ActionCable
      class ServerDriver
        def self.publish(channels, message)
          channels.each do |channel|
            ActionCable.server.broadcast(channel, message)
          end
        end
      end
    end
  end
end