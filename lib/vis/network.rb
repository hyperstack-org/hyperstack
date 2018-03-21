module Vis
  class Network
    include Native
    include Vis::Utilities

    aliases_native %i[
      addEdgeMode
      addNodeMode
      deleteSelected
      destroy
      editEdgeMode
      editNode
      enableEditMode
      disableEditMode
      findNode 
      getBaseEdges 
      getClusteredEdges
      getConnectedEdges
      getConnectedNodes
      getNodesInCluster
      getScale
      getSeed
      getSelectedEdges
      getSelectedNodes
      isCluster
      moveNode
      redraw
      releaseNode
      selectEdges
      selectNodes
      stabilize
      startSimulation
      stopSimulation
      storePositions
      unselectAll
    ]

    def initialize(native_container, dataset_hash, options = {})
      native_options = options_to_native(options)
      nodes_dataset = dataset_hash[:nodes].to_n
      edges_dataset = dataset_hash[:edges].to_n
      native_data = `{ nodes: nodes_dataset, edges: edges_dataset }`
      @event_handlers = {}
      @native = `new vis.Network(native_container, native_data, native_options)`
    end

    # global methods

    def off(event, event_handler_id)
      event = lower_camelize(event)
      handler = @event_handlers[event][event_handler_id]
      `self["native"].off(event, handler)`
      @event_handlers[event].delete(event_handler_id)
    end

    EVENTS_NO_COVERSION = %i[afterDrawing beforeDrawing blurEdge blurNode hoverEdge hoverNode showPopup]
    EVENTS_NO_PARAM = %i[hidePopup startStabilizing stabilizationIterationsDone initRedraw]
    
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

    def once(event, &block)
      handler = if EVENTS_NO_COVERSION.include?(event)
        `function(param) { #{block.call(`param`)}; }`
      elsif EVENTS_NO_PARAM.include?(event)
        `function() { #{block.call}; }`
      else
        `function(event_info) { #{block.call(`Opal.Hash.$new(event_info)`)}; }`
      end
      `self["native"].once(event, handler);`
    end

    def set_data(dataset_hash)
      nodes_dataset = dataset_hash[:nodes].to_n
      edges_dataset = dataset_hash[:edges].to_n
      native_data = `{ nodes: nodes_dataset, edges: edges_dataset }`
      @native.JS.setData(native_data)
    end

    def set_options(options)
      native_options = options_to_native(options)
      @native.JS.setOptions(native_options)
    end

    # canvas methods

    def canvas_to_dom(xy_hash)
      res = @native.JS.canvasToDOM(xy_hash.to_n)
      `Opal.Hash.$new(res)`
    end

    def dom_to_canvas(xy_hash)
      res = @native.JS.DOMtoCanvas(xy_hash.to_n)
      `Opal.Hash.$new(res)`
    end

    def set_size(width, height)
      width = width.to_s
      height = height.to_s
      @native.JS.setSize(width, height)
    end

    # clustering

    def cluster(options)
      @native.JS.cluster(options_to_native(options))
    end

    def cluster_by_connection(node_id, options = {})
      @native.JS.clusterByConnection(node_id, options_to_native(options))
    end

    def cluster_by_hubsize(hub_size, options = {})
      @native.JS.clusterByHubsize(hub_size, options_to_native(options))
    end

    def cluster_outliers(options)
      @native.JS.clusterOutliers(options_to_native(options))
    end

    def open_cluster(node_id, options)
      @native.JS.openCluster(node_id, options_to_native(options))
    end

    def update_edge(start_edge_id, options)
      @native.JS.updateEdge(start_edge_id, options_to_native(options))
    end

    def update_clustered_node(clustered_node_id, options)
      @native.JS.updateClusteredNode(start_edge_id, options_to_native(options))
    end

    # information

    def get_bounding_box(node_id)
      res = @native.JS.getBoundingBox(node_id)
      `Opal.Hash.$new(res)`
    end

    def get_positions(array_of_node_ids)
      res = @native.JS.getPositions(array_of_node_ids)
      `Opal.Hash.$new(res)`
    end

    # selection

    def get_edge_at(dom_xy_hash)
      @native.JS.getEdgeAt(xy_hash.to_n)
    end

    def get_node_at(dom_xy_hash)
      @native.JS.getNodeAt(xy_hash.to_n)
    end

    def get_selection
      res = @native.JS.getSelection
      `Opal.Hash.$new(res)`
    end

    def set_selection(selection_hash, options = {})
      @native.JS.setSelection(selection_hash.to_n, options_to_native(options))
    end

    # viewport

    def fit(options = {})
      @native.JS.fit(options_to_native(options))
    end

    def focus(node_id, options = {})
      @native.JS.focus(node_id, options_to_native(options))
    end

    def get_view_position
      res = @native.JS.getViewPosition
      `Opal.Hash.$new(res)`
    end

    def move_to(options)
      @native.JS.moveTo(options_to_native(options))
    end

    # configurator module
    def get_options_from_configurator
      res = @native.JS.getOptionsFromConfigurator
      `Opal.Hash.$new(res)`
    end

    # importing data
    def self.convert_gephi(gephi_json, options)
      native_options = options_to_native(options)
      res = `vis.network.convertGephi(gephi_json, native_options)`
      `Opal.Hash.$new(res)`
    end

    def self.convert_dot(dot_string)
      res = `vis.network.convertDot(dot_string)`
      `Opal.Hash.$new(res)`
    end

    # options

    def options_to_native(options)
      return unless options
      # options must be duplicated, so callbacks dont get wrapped twice
      new_opts = {}.merge!(options)
      _rubyfy_configure_options(new_opts) if new_opts.has_key?(:configure)
      _rubyfy_edges_options(new_opts) if new_opts.has_key?(:edges)
      _rubyfy_manipulation_options(new_opts) if new_opts.has_key?(:manipulation)
      _rubyfy_nodes_options(new_opts) if new_opts.has_key?(:nodes)

      if new_opts.has_key?(:join_condition)
        block = new_opts[:join_condition]
        if `typeof block === "function"`
          unless new_opts[:join_condition].JS[:hyper_wrapped]
            new_opts[:join_condition] = %x{
              function(node_options, child_options) {
                if (child_options !== undefined && child_options !== null) {
                  return #{block.call(`Opal.Hash.$new(node_options)`, `Opal.Hash.$new(child_options)`)};
                } else {
                  return #{block.call(`Opal.Hash.$new(node_options)`)};
                }
              }
            }
            new_opts[:join_condition].JS[:hyper_wrapped] = true
          end
        end
      end

      if new_opts.has_key?(:process_properties)
        block = new_opts[:process_properties]
        if `typeof block === "function"`
          unless new_opts[:process_properties].JS[:hyper_wrapped]
            new_opts[:process_properties] = %x{
              function(item) {
                var res = #{block.call(`Opal.Hash.$new(item)`)};
                return res.$to_n();
              }
            }
            new_opts[:process_properties].JS[:hyper_wrapped] = true
          end
        end
      end

      lower_camelize_hash(new_opts).to_n
    end

    def _rubyfy_configure_options(options)
      if options[:configure].has_key?(:filter)
        block = options[:configure][:filter]
        if `typeof block === "function"`
          unless options[:configure][:filter].JS[:hyper_wrapped]
            options[:configure][:filter] = %x{
              function(option, path) {
                return #{block.call(`Opal.Hash.$new(options)`, `path`)};
              }
            }
            options[:configure][:filter].JS[:hyper_wrapped] = true
          end
        end
      end
    end

    def _rubyfy_edges_options(options)
      if options[:edges].has_key?(:chosen)
        chosen = options[:edges][:chosen]
        [:edge, :label].each do |key|
          if chosen.has_key?(key)
            block = chosen[key]
            if `typeof block === "function"`
              unless options[:edges][:chosen][key].JS[:hyper_wrapped]
                options[:edges][:chosen][key] = %x{
                  function(values, id, selected, hovering) {
                    return #{block.call(`Opal.Hash.$new(values)`, `id`, `selected`, `hovering`)};
                  }
                }
                options[:edges][:chosen][key].JS[:hyper_wrapped] = true
              end
            end
          end
        end
      end
      [:hover_width, :selection_width].each do |key|
        if options[:edges].has_key?(key)
          block = options[:edges][key]
          if `typeof block === "function"`
            unless options[:edges][key].JS[:hyper_wrapped]
              options[:edges][key] = %x{
                function(width) {
                  return #{block.call(`width`)};
                }
              }
              options[:edges][key].JS[:hyper_wrapped] = true
            end
          end
        end
      end
      if options[:edges].has_key?(:scaling)
        if options[:edges][:scaling].has_key?(:custom_scaling_function)
          block = options[:edges][:scaling][:custom_scaling_function]
          if `typeof block === "function"`
            unless options[:edges][:scaling][:custom_scaling_function].JS[:hyper_wrapped]
              options[:edges][:scaling][:custom_scaling_function] = %x{
                function(min, max, total, value) {
                  return #{block.call(`min`, `max`, `total`, `value`)};
                }
              }
              options[:edges][:scaling][:custom_scaling_function].JS[:hyper_wrapped] = true
            end
          end
        end
      end
    end

    def _rubyfy_manipulation_options(options)
      [:add_edge, :add_node, :edit_edge, :edit_node].each do |key|
        next unless options[:manipulation].has_key?(key)
        block = options[:manipulation][key]
        if `typeof block === "function"`
          unless options[:manipulation][key].JS[:hyper_wrapped]
            options[:manipulation][key] = %x{
              function(nodeData, callback) {
                var wrapped_callback = #{ proc { |new_node_data| `callback(new_node_data.$to_n());` }};
                block.$call(Opal.Hash.$new(nodeData), wrapped_callback);
              }
            }
          end
          options[:manipulation][key].JS[:hyper_wrapped] = true
        end
      end
      # for delete the order of args for the callback is not clear
      [:delete_edge, :delete_node].each do |key|
        next unless options[:manipulation].has_key?(key)
        block = options[:manipulation][key]
        if `typeof block === "function"`
          unless options[:manipulation][key].JS[:hyper_wrapped]
            options[:manipulation][key] = %x{
              function(nodeData, callback) {
                var wrapped_callback = #{ proc { |new_node_data| `callback(new_node_data.$to_n());` }};
                block.$call(Opal.Hash.$new(nodeData), wrapped_callback);
              }
            }
            options[:manipulation][key].JS[:hyper_wrapped] = true
          end
        end
      end
    end

    def _rubyfy_nodes_options(options)
      if options[:nodes].has_key?(:chosen)
        chosen = options[:nodes][:chosen]
        [:node, :label].each do |key|
          if chosen.has_key?(key)
            block = chosen[key]
            if `typeof block === "function"`
              unless options[:nodes][:chosen][key].JS[:hyper_wrapped]
                options[:nodes][:chosen][key] = %x{
                  function(values, id, selected, hovering) {
                    return #{block.call(`Opal.Hash.$new(values)`, `id`, `selected`, `hovering`)};
                  }
                }
                options[:nodes][:chosen][key].JS[:hyper_wrapped] = true
              end
            end
          end
        end
      end
      if options[:nodes].has_key?(:scaling)
        if options[:nodes][:scaling].has_key?(:custom_scaling_function)
          block = options[:nodes][:scaling][:custom_scaling_function]
          if `typeof block === "function"`
            unless options[:nodes][:scaling][:custom_scaling_function].JS[:hyper_wrapped]
              options[:nodes][:scaling][:custom_scaling_function] = %x{
                function(min, max, total, value) {
                  return #{block.call(`min`, `max`, `total`, `value`)};
                }
              }
              options[:nodes][:scaling][:custom_scaling_function].JS[:hyper_wrapped] = true
            end
          end
        end
      end
    end
  end
end