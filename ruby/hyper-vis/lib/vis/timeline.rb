module Vis
  class Timeline
    include Native
    include Vis::Utilities

    aliases_native %i[
      addCustomTime
      destroy
      getCurrentTime
      getCustomTime
      getSelection
      getVisibleItems
      redraw
      removeCustomTime
      setCurrentTime
      setCustomTime
      setCustomTimeTitle
      toggleRollingMode
    ]

    def initialize(native_container, dataset, group_dataset = nil, options = {})
      if group_dataset.is_a?(Hash)
        options = group_dataset
        group_dataset = nil
      end
      native_options = options_to_native(options)
      native_data = dataset.to_n
      @event_handlers = {}
      if group_dataset.nil?
        @native = `new vis.Timeline(native_container, native_data, native_options)`
      else
        native_group_data = group_dataset.to_n
        @native = `new vis.Timeline(native_container, native_data, native_group_data, native_options)`
      end
    end

    def off(event, event_handler_id)
      event = lower_camelize(event)
      handler = @event_handlers[event][event_handler_id]
      `self["native"].off(event, handler)`
      @event_handlers[event].delete(event_handler_id)
    end

    EVENTS_NO_COVERSION = %i[groupDragged]
    EVENTS_NO_PARAM = %i[currentTimeTick changed]
    
    def on(event, &block)
      event = lower_camelize(event)
      @event_handlers[event] = {} unless @event_handlers[event]
      event_handler_id = `Math.random().toString(36).substring(6)`
      handler = if EVENTS_NO_COVERSION.include?(event)
        `function(param) { #{block.call(`param`)}; }`
      elsif EVENTS_NO_PARAM.include?(event)
        `function() { #{block.call}; }`
      else
        `function(event_info) { #{block.call(`Opal.Hash.$new(event_info)`)}; }`
      end
      @event_handlers[event][event_handler_id] = handler
      `self["native"].on(event, handler);`
      event_handler_id
    end

    def set_data(dataset_hash)
      native_data_hash = {}
      native_data_hash[:groups] = dataset_hash[:groups].to_n if dataset_hash.has_key?(:groups)
      native_data_hash[:items] = dataset_hash[:items].to_n if dataset_hash.has_key?(:items)
      @native.JS.setData(native_data_hash.to_n)
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

    def fit(options = {})
      @native.JS.fit(options_to_native(options))
    end

    def focus(node_id, options = {})
      @native.JS.focus(node_id, options_to_native(options))
    end

    def get_event_properties(event)
      res = @native.JS.getEventProperties(event.to_n)
      `Opal.Hash.$new(res)`
    end

    def get_item_range
      res = @native.JS.getItemRange()
      `Opal.Hash.$new(res)`
    end

    def get_window
      res = @native.JS.getWindow()
      `Opal.Hash.$new(res)`
    end
    
    def move_to(time, options = {})
      @native.JS.moveTo(time, options_to_native(options))
    end

    def set_selection(id_or_ids, options = {})
      @native.JS.setSelection(id_or_ids, options_to_native(options))
    end

    def set_window(start_time, end_time, options = {}, &block)
      native_options = options_to_native(options)
      if block_given?
        callback = %x{
          function() {
            return block.$call();
          }
        }
        @native.JS.setWindow(start_time, end_time, native_options, callback)
      else
        @native.JS.setWindow(start_time, end_time, native_options)
      end
    end

    def zoom_in(percentage, options = {}, &block)
      native_options = options_to_native(options)
      if block_given?
        callback = %x{
          function() {
            return block.$call();
          }
        }
        @native.JS.zoomIn(percentage, native_options, callback)
      else
        @native.JS.zoomIn(percentage, native_options)
      end
    end

    def zoom_out(percentage, options = {}, &block)
      native_options = options_to_native(options)
      if block_given?
        callback = %x{
          function() {
            return block.$call();
          }
        }
        @native.JS.zoomOut(percentage, native_options, callback)
      else
        @native.JS.zoomOut(percentage, native_options)
      end
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
                return #{block.call(`option`, `path`)};
              }
            }
            new_opts[:configure].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:format)
        block = new_opts[:format]
        if `typeof block === "function"`
          unless new_opts[:format].JS[:hyper_wrapped]
            # this is not clear in the vis docs
            new_opts[:format] = %x{
              function(object) {
                return #{block.call(`Opal.Hash.$new(object)`)};
              }
            }
            new_opts[:format].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:group_order)
        block = new_opts[:group_order]
        if `typeof block === "function"`
          unless new_opts[:group_order].JS[:hyper_wrapped]
            # this is not clear in the vis docs
            new_opts[:group_order] = %x{
              function() {
                return #{block.call};
              }
            }
            new_opts[:group_order].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:group_order_swap)
        block = new_opts[:group_order_swap]
        if `typeof block === "function"`
          unless new_opts[:group_order_swap].JS[:hyper_wrapped]
            # this is not clear in the vis docs
            new_opts[:group_order_swap] = %x{
              function(from_group, to_group, groups) {
                return #{block.call(`Opal.Hash.$new(from_group)`, `Opal.Hash.$new(to_group)`, Vis::DataSet.wrap(groups))};
              }
            }
            new_opts[:group_order_swap].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:group_template)
        block = new_opts[:group_template]
        if `typeof block === "function"`
          unless new_opts[:group_template].JS[:hyper_wrapped]
            # this is not clear in the vis docs
            new_opts[:group_template] = %x{
              function(groups, group_element) {
                return #{block.call(Vis::DataSet.wrap(groups), `Opal.Hash.$new(group_element)`)};
              }
            }
            new_opts[:group_template].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:moment)
        block = new_opts[:moment]
        if `typeof block === "function"`
          unless new_opts[:moment].JS[:hyper_wrapped]
            new_opts[:moment] = %x{
              function(native_date) {
                return #{block.call(`native_date`)};
              }
            }
            new_opts[:moment].JS[:hyper_wrapped] = true
          end
        end
      end

      %i[on_add on_add_group on_move on_move_group on_moving on_remove on_remove_group on_update].each do |key|
        if new_opts.has_key?(key)
          block = new_opts[key]
          if `typeof block === "function"`
            unless new_opts[key].JS[:hyper_wrapped]
              new_opts[key] = %x{
                function(item, callback) {
                  var wrapped_callback = #{ proc { |new_node_data| `callback(new_item.$to_n());` }};
                  block.$call(Opal.Hash.$new(item), wrapped_callback);
                }
              }
              new_opts[key].JS[:hyper_wrapped] = true
            end
          end
        end
      end

      if new_opts.has_key?(:on_drop_object_on_item)
        block = new_opts[on_drop_object_on_item]
        if `typeof block === "function"`
          unless new_opts[on_drop_object_on_item].JS[:hyper_wrapped]
            new_opts[on_drop_object_on_item] = %x{
              function(object, item) {
                block.$call(Opal.Hash.$new(object), Opal.Hash.$new(item));
              }
            }
            new_opts[on_drop_object_on_item].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:on_initial_draw_complete)
        block = new_opts[:on_initial_draw_complete]
        if `typeof block === "function"`
          unless new_opts[:on_initial_draw_complete].JS[:hyper_wrapped]
            new_opts[:on_initial_draw_complete] = %x{
              function() { block.$call(); }
            }
            new_opts[:on_initial_draw_complete].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:snap)
        block = new_opts[:snap]
        if `typeof block === "function"`
          unless new_opts[:snap].JS[:hyper_wrapped]
            new_opts[:snap] = %x{
              function(date, scale, step) {
                return block.$call(date, scale, step);
              }
            }
            new_opts[:snap].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:template)
        block = new_opts[:template]
        if `typeof block === "function"`
          unless new_opts[:template].JS[:hyper_wrapped]
            # not clear in vis docs
            new_opts[:template] = %x{
              function(item, element, edited_data) {
                return block.$call(Opal.Hash.$new(item), element, Opal.Hash.$new(edited_data));
              }
            }
            new_opts[:template].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:visible_frame_template)
        block = new_opts[:visible_frame_template]
        if `typeof block === "function"`
          unless new_opts[:visible_frame_template].JS[:hyper_wrapped]
            # not clear in vis docs
            new_opts[:visible_frame_template] = %x{
              function(item, element) {
                return block.$call(Opal.Hash.$new(item), element);
              }
            }
            new_opts[:visible_frame_template].JS[:hyper_wrapped] = true
          end
        end
      end

      lower_camelize_hash(new_opts).to_n
    end
  end
end