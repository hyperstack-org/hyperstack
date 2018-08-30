module Vis
  module EventSupport
    def off(event, event_handler_id)
      event = lower_camelize(event)
      handler = @event_handlers[event].delete(event_handler_id)
      `self["native"].off(event, handler)` if handler
      nil
    end

    def on(event, &block)
      event = lower_camelize(event)
      @event_handlers[event] = {} unless @event_handlers[event]
      event_handler_id = `Math.random().toString(36).substring(6)`
      handler = %x{
        function(event_str, properties, sender_id) {
          #{block.call(`event_str`, `Opal.Hash.$new(properties)`, `sender_id`)};
        }
      }
      @event_handlers[event][event_handler_id] = handler
      `self["native"].on(event, handler);`
      event_handler_id
    end
  end
end