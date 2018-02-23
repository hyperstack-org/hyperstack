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
    
    def on(event, &block)
      event = lower_camelize(event)
      @event_handlers[event] = {} unless @event_handlers[event]
      event_handler_id = `Math.random().toString(36).substring(6)`
      handler = %x{
        function(event_info) {
          #{block.call(`Opal.Hash.$new(event_info)`)};
        }
      }
      @event_handlers[event][event_handler_id] = handler
      `self["native"].on(event, handler);`
      event_handler_id
    end

    def once(event, &block)
      handler = %x{
        function(event_info) {
          #{block.call(`Opal.Hash.$new(event_info)`)};
        }
      }
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

    def cluster_by_connection(node_id, options)
      @native.JS.clusterByConnection(node_id, options_to_native(options))
    end

    def cluster_by_hubsize(hub_size, options)
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

    def set_selection(selection_hash, options)
      @native.JS.setSelection(selection_hash.to_n, options_to_native(options))
    end

    # viewport

    def fit(options)
      @native.JS.fit(options_to_native(options))
    end

    def focus(node_id, options)
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

    # test helper
    def self.test_container
      `document.body.appendChild(document.createElement('div'))`
    end
  end
end