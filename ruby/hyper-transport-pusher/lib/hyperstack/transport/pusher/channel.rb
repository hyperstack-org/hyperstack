module Hyperstack
  module Transport
    module Pusher
      class Channel
        def self.pusher_instance
          @pusher_instance ||= Hyperstack::Transport::Pusher::ClientDriver.pusher_instance
        end

        def self.channels
          @channels ||= []
        end

        def self.event_handlers
          @event_handlers ||= {}
        end

        def self.unbind(event, event_handler_id)
          handler = event_handlers[event]&.delete(event_handler_id)
          pusher_instance.JS.unbind(event, handler) if handler
        end

        def self.bind(event, &block)
          event_handlers[event] = {} unless event_handlers.has_key?[event]
          event_handler_id = `Math.random().toString(36).substring(6)`
          handler = %x{
            function(data) {
              #{block.call(`Opal.Hash.$new(data)`)};
            }
          }
          event_handlers[event][event_handler_id] = handler
          pusher_instance.JS.bind(event, handler);
          event_handler_id
        end

        def self.disconnect
          pusher_instance.JS.disconnect
          nil
        end

        def self.state
          pusher_instance.JS.state
        end

        def self.subscribe(channel)
          pusher_instance.JS.subscribe(channel)
          channels << channel
          nil
        end

        def self.unsubscribe(channel)
          pusher_instance.JS.unsubscribe(channel)
          channels.delete(channel)
          nil
        end
      end
    end
  end
end
