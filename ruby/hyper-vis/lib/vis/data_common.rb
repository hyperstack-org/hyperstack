module Vis
  module DataCommon
    def [](id)
      get(id)
    end

    def get(*args)
      if `Opal.is_a(args.$last(), Opal.Hash)`
        args.push(options_to_native(args.pop))
      end
      res = `self["native"].get.apply(self["native"], Opal.to_a(args))`
      if `res !== null && Opal.is_a(res, Opal.Array)`
        native_to_hash_array(res)
      else
        `res !== null ? Opal.Hash.$new(res) : #{nil}`
      end
    end

    def get_ids(options)
      @native.JS.getIds(options_to_native(options))
    end

    # events
    
    def off(event, event_handler_id)
      event = lower_camelize(event)
      handler = @event_handlers[event][event_handler_id]
      `self["native"].off(event, handler)`
      @event_handlers[event].delete(event_handler_id)
    end

    def on(event, &block)
      event = lower_camelize(event)
      @event_handlers[event] = {} unless @event_handlers[event]
      event_handler_id = `Math.random().toString(36).substring(6)`
      handler = %x{
        function(event, properties, sender_id) {
          return block.$call(Opal.Hash.$new(event),Opal.Hash.$new(properties), sender_id);
        }
      }
      @event_handlers[event][event_handler_id] = handler
      `self["native"].on(event, handler);`
      event_handler_id
    end
    
    # options

    def options_to_native(options)
      return unless options
      new_opts = {}.merge!(options)

      if new_opts.has_key?(:filter)
        block = new_opts[:filter]
        if `typeof block === "function"`
          unless new_opts[:filter].JS[:hyper_wrapped]
            new_opts[:filter] = %x{
              function(item) {
                return #{block.call(`Opal.Hash.$new(item)`)};
              }
            }
            new_opts[:filter].JS[:hyper_wrapped] = true
          end
        end
      end
      
      lower_camelize_hash(new_opts).to_n
    end
  end
end