module Hyperloop
  module Transport
    module Pusher
      module EventSupport
        def native_unbind(native, event, event_handler_id)
          handler = @event_handlers[event]&.delete(event_handler_id)
          native.JS.unbind(event, handler) if handler
        end

        def native_bind(native, event, &block)
          @event_handlers[event] = {} unless @event_handlers[event]
          event_handler_id = `Math.random().toString(36).substring(6)`
          handler = %x{
            function(data) {
              #{block.call(`Opal.Hash.$new(data)`)};
            }
          }
          @event_handlers[event][event_handler_id] = handler
          native.JS.bind(event, handler);
          event_handler_id
        end
      end
    end
  end
end
