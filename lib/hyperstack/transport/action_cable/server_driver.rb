module Hyperstack
  module Transport
    module ActionCable
      class ServerDriver
        def self.publish(channels, message)
          if channels.class == String # just one channel
            ::ActionCable.server.broadcast(channels, message)
          else
            channels.each do |channel| # many channels
              ::ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end
    end
  end
end