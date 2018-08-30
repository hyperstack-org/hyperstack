module Vis
  class Graph2d
    include Native
    include Vis::Utilities

    aliases_native %i[
      addCustomTime
      destroy
      fit
      getCurrentTime
      getCustomTime
      isGroupVisible
      redraw
      removeCustomTime
      setCurrentTime
      setCustomTime
      setWindow
    ]

    def initialize(native_container, item_dataset, group_dataset = nil, options = {})
      native_item_data = item_dataset.to_n
      if group_dataset.is_a?(Hash) && options == {}
        options = group_dataset
        group_dataset = nil
      end
      native_options = options_to_native(options)
      @event_handlers = {}
      if group_dataset.nil?
        @native = `new vis.Graph2d(native_container, native_item_data, native_options)`
      else
        native_group_data = group_dataset.to_n
        @native = `new vis.Graph2d(native_container, native_item_data, native_group_data, native_options)`
      end
    end

    def off(event, event_handler_id)
      event = lower_camelize(event)
      handler = @event_handlers[event][event_handler_id]
      `self["native"].off(event, handler)`
      @event_handlers[event].delete(event_handler_id)
    end

    EVENTS_NO_PARAM = %i[currentTimeTick changed]
    
    def on(event, &block)
      event = lower_camelize(event)
      @event_handlers[event] = {} unless @event_handlers[event]
      event_handler_id = `Math.random().toString(36).substring(6)`
      handler = if EVENTS_NO_PARAM.include?(event)
        `function() { block.$call(); }`
      else
        `function(event_info) { block.$call(Opal.Hash.$new(event_info)); }`
      end
      @event_handlers[event][event_handler_id] = handler
      `self["native"].on(event, handler)`
      event_handler_id
    end

    def set_groups(dataset)
      @native.JS.setGroups(dataset.to_n)
    end
    
    def set_items(dataset)
      @native.JS.setItems(dataset.to_n)
    end

    def set_options(options)
      @native.JS.setOptions(options_to_native(options))
    end

    def get_data_range
      res = @native.JS.getDataRange()
      `Opal.Hash.$new(res)`
    end

    def get_event_properties(event)
      res = @native.JS.getEventProperties(event.to_n)
      `Opal.Hash.$new(res)`
    end
    
    def get_legend(group_id, icon_width, icon_height)
      res = @native.JS.getLegend(group_id, icon_width, icon_height)
      `Opal.Hash.$new(res)`
    end

    def get_window
      res = @native.JS.getWindow()
      `Opal.Hash.$new(res)`
    end

    def move_to(time, options = {})
      @native.JS.moveTo(time, options_to_native(options))
    end

    def options_to_native(options)
      return unless options
      # options must be duplicated, so callbacks dont get wrapped twice
      new_opts = {}.merge!(options)

      if new_opts.has_key?(:configure)
        block = new_opts[:configure]
        if `typeof block === "function"`
          unless new_opts[:configure].JS[:hyper_wrapped]
            new_opts[:configure] = %x{
              function(option, path) {
                return block.$call(option, path);
              }
            }
            new_opts[:configure].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:draw_points)
        block = new_opts[:draw_points]
        if `typeof block === "function"`
          unless new_opts[:draw_points].JS[:hyper_wrapped]
            new_opts[:draw_points] = %x{
              function(item, group) {
                return block.$call(Opal.Hash.$new(item), Opal.Hash.$new(group));
              }
            }
            new_opts[:draw_points].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:moment)
        block = new_opts[:moment]
        if `typeof block === "function"`
          unless new_opts[:moment].JS[:hyper_wrapped]
            new_opts[:moment] = %x{
              function(native_date) {
                return block.$call(native_date);
              }
            }
            new_opts[:moment].JS[:hyper_wrapped] = true
          end
        end
      end

      lower_camelize_hash(new_opts).to_n
    end
  end
end