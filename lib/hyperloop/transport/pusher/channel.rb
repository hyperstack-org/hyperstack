module Hyperlooop
  module Transport
    module Pusher
      class Channel
        include Hyperloop::Transport::Pusher::EventSupport

        attr_reader :channels
        attr_reader :handler

        def initialize(options)
          key = options.delete(:key)
          @channels = []
          @event_handlers = {}
          channel = options.delete(:channel)
          @channels << channel if channel
          client_logging = options.delete(:client_logging)
          if client_logging
            `Pusher.log = function(m) { console.log(message); }`
          end
          @native_pusher_instance = `new Pusher(key, options.$to_n())`
          @native_pusher_channel = @native_pusher_instance.JS.subscribe(channel) if channel
        end

        def bind(event, &block)
          native_bind(@native_pusher_channel, event, &block)
        end

        def unbind(event, event_handler_id)
          native_unbind(@native_pusher_channel, event, event_handler_id)
          nil
        end

        def disconnect
          @native_pusher_instance.JS.disconnect
          nil
        end

        def state
          @native_pusher_instance.JS.state
        end

        def subscribe(channel)
          @native_pusher_channel = @native_pusher_instance.JS.subscribe(channel)
          @channels << channel
          nil
        end

        def unsubscribe(channel)
          @native_pusher_instance.JS.unsubscribe(channel)
          @channels.delete(channel)
          nil
        end
      end
    end
  end
end
