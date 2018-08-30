require 'spec_helper'

describe 'Vis::Network', js: true do

  it 'creates a new Network' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      [net.is_a?(Vis::Network), dom_node.JS[:children].JS[:length]]
    end.to eq([true, 1])
  end

  it 'creates a new Network and destroys it' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      net.destroy
      [net.is_a?(Vis::Network), created, dom_node.JS[:children].JS[:length]]
    end.to eq([true, 1, 0])
  end
  
  it 'it can replace the data' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      old_position = net.find_node(1)
      new_dataset = Vis::DataSet.new([{id: 4, name: 'club'}, {id: 5, name: 'bar'}, {id: 6, name: 'pub'}])
      net.set_data(nodes: new_dataset)
      position = net.find_node(4)
      invalid_position = net.find_node(1)
      [net.is_a?(Vis::Network), created, old_position, position, invalid_position]
    end.to eq([true, 1, [1], [4], []])
  end

  it 'it can set options' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      error = false
      begin
        net.set_options({
          :autoResize => true,
          :locale => 'en',
          :nodes => {
            :scaling => {
              :min => 16,
              :max => 32
            },
            :shadow => true
          },
          :edges => {
            :color => "#ff0000",
            :smooth => false,
            :shadow => true
          }
        })
      rescue
        error = true
      end
      [net.is_a?(Vis::Network), created, error]
    end.to eq([true, 1, false])
  end

  it 'it can set and remove a event listener' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      received = []
      handler_id = net.on(:resize) do |event_info|
        received << event_info
      end
      net.set_size(100, 100)
      net.off(:resize, handler_id)
      net.set_size(200, 200)
      [net.is_a?(Vis::Network), created, received.size]
    end.to eq([true, 1, 1])
  end
  
  it 'it can set a event listener thats called once' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      received = []
      handler_id = net.once(:resize) do |event_info|
        received << event_info
      end
      net.set_size(100, 100)
      net.set_size(200, 200)
      [net.is_a?(Vis::Network), created, received.size]
    end.to eq([true, 1, 1])
  end

  it 'translates canvas coordinates to dom coordinatea' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      xy = net.canvas_to_dom({x: 10, y: 10})
      [net.is_a?(Vis::Network), created, xy[:x] > 10, xy[:y] > 10]
    end.to eq([true, 1, true, true])
  end

  it 'translates dom coordinates to canvas coordinates' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      xy = net.dom_to_canvas({x: 10, y: 10})
      [net.is_a?(Vis::Network), created, xy[:x] < 0, xy[:y] < 0]
    end.to eq([true, 1, true, true])
  end

  it 'can call redraw' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      net.redraw
      redrawn = dom_node.JS[:children].JS[:length]
      [net.is_a?(Vis::Network), created, redrawn]
    end.to eq([true, 1, 1])
  end

  it 'set the size of the canvas' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      before_canvas_width = dom_node.JS.querySelector('canvas').JS[:width]
      before_canvas_height = dom_node.JS.querySelector('canvas').JS[:height]
      net.set_size(50, 50)
      after_canvas_width = dom_node.JS.querySelector('canvas').JS[:width]
      after_canvas_height = dom_node.JS.querySelector('canvas').JS[:height]
      # vis accounts for retina displays for example, so the actual size reported by
      # by the dom canvas element is not what is set by set_size, thats why we do this:
      [net.is_a?(Vis::Network), created, before_canvas_width > after_canvas_width, before_canvas_height > after_canvas_height]
    end.to eq([true, 1, true, true])
  end

  it 'creates a cluster and finds node in it' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster(join_condition: proc { |node_options| true })
      node_pos = net.find_node(2)
      [net.is_a?(Vis::Network), created, node_pos.first.start_with?('cluster:'), node_pos.last]
    end.to eq([true, 1, true, 2])
  end

  it 'creates a cluster by connection' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster_by_connection(2)
      node_pos = net.find_node(2)
      [net.is_a?(Vis::Network), created, node_pos.first.start_with?('cluster:'), node_pos.last]
    end.to eq([true, 1, true, 2])
  end

  it 'creates a cluster by hubsize' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster_by_hubsize(2)
      node_pos = net.find_node(2)
      [net.is_a?(Vis::Network), created, node_pos.first.start_with?('cluster:'), node_pos.last]
    end.to eq([true, 1, true, 2])
  end

  it 'clusters the outliers' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster_outliers
      node_pos = net.find_node(1)
      [net.is_a?(Vis::Network), created, node_pos.first.start_with?('cluster:'), node_pos.last]
    end.to eq([true, 1, true, 1])
  end

  xit 'get clustered edges' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{id: 'one', from: 1, to: 2}, {id: 'two', from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster(join_condition: proc { |node_options| true })
      edges = net.get_clustered_edges('one')
      [net.is_a?(Vis::Network), created, edges]
    end.to eq([true, 1, true])
  end

  xit 'getBaseEdges'
  xit 'updateEdge'
  xit 'updateClusteredNode'

  it 'clusters is a cluster' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster_outliers
      pos = net.find_node(1)
      is_cluster = net.is_cluster(pos[0])
      [net.is_a?(Vis::Network), created, is_cluster]
    end.to eq([true, 1, true])
  end

  it 'gets nodes in cluster' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster_outliers
      pos = net.find_node(1)
      nodes = net.get_nodes_in_cluster(pos[0])
      [net.is_a?(Vis::Network), created, nodes]
    end.to eq([true, 1, [1, 2, 3]])
  end

  it 'opens the cluster' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.cluster_outliers
      pos = net.find_node(1)
      before_is_cluster = net.is_cluster(pos[0])
      net.open_cluster(pos[0])
      after_is_cluster = net.is_cluster(pos[0])
      [net.is_a?(Vis::Network), created, before_is_cluster, after_is_cluster]
    end.to eq([true, 1, true, false])
  end

  it 'can get the seed' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      seed = net.get_seed
      [net.is_a?(Vis::Network), created, seed.is_a?(Integer)]
    end.to eq([true, 1, true])
  end

  # use callback method in options for the following
  it 'it selects a node, enables edit mode, edits node, disables edit mode' do
    expect_evaluate_ruby do
      received_data = []
      options = { manipulation: {
        edit_node: proc { |node_data, callback| received_data << node_data }
      }}
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset}, options)
      created = dom_node.JS[:children].JS[:length]
      net.enable_edit_mode
      net.select_nodes([1])
      net.edit_node
      net.disable_edit_mode
      [net.is_a?(Vis::Network), created, received_data.first[:name]]
    end.to eq([true, 1, 'foo'])
  end

  it 'can select nodes and delete them' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.select_nodes([1])
      net.delete_selected
      res = dataset.get(1)
      [net.is_a?(Vis::Network), created, res]
    end.to eq([true, 1, nil])
  end

  it 'can get the positions of nodes' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      positions = net.get_positions(['1', '2'])
      [net.is_a?(Vis::Network), created, positions.size, positions['1']['x'].is_a?(Integer)]
    end.to eq([true, 1, 2, true])
  end

  it 'can store the positions of nodes' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.store_positions
      item = dataset.get(1)
      [net.is_a?(Vis::Network), created, item.has_key?(:x), item[:x].is_a?(Integer)]
    end.to eq([true, 1, true, true])
  end

  it 'can move a node' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      before_position = net.get_positions(['1'])
      net.move_node('1', 10, 10)
      after_position = net.get_positions(['1'])
      [net.is_a?(Vis::Network), created,
       before_position['1'][:x] != after_position['1'][:x],
       before_position['1'][:y] != after_position['1'][:y],
       after_position['1'][:x],
       after_position['1'][:y]]
    end.to eq([true, 1, true, true, 10, 10])
  end

  it 'gets the bounding box of a node' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      bounding_box = net.get_bounding_box(['1'])
      [net.is_a?(Vis::Network), created,
       bounding_box[:top].is_a?(Integer),
       bounding_box[:left].is_a?(Integer),
       bounding_box[:right].is_a?(Integer),
       bounding_box[:bottom].is_a?(Integer)]
    end.to eq([true, 1, true, true, true, true])
  end

  it 'it can get connected nodes' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      connected_nodes = net.get_connected_nodes(1)
      [net.is_a?(Vis::Network), created, connected_nodes]
    end.to eq([true, 1, [2]])
  end
  
  it 'it can get connected edges' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      connected_edges = net.get_connected_edges(1)
      [net.is_a?(Vis::Network), created, connected_edges.first.is_a?(String)]
    end.to eq([true, 1, true])
  end

  it 'can call physics methods' do
    # just checking if we can call them, not testing functionality
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      error = false
      begin
        net.start_simulation
        net.stop_simulation
        net.stabilize
      rescue
        error = true
      end
      [net.is_a?(Vis::Network), created, error]
    end.to eq([true, 1, false])
  end

  it 'can make a selection and get the selection' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      edges = net.get_connected_edges(1)
      net.set_selection(nodes: [1], edges: edges)
      selection = net.get_selection
      [net.is_a?(Vis::Network), created,
       selection.has_key?(:nodes),
       selection.has_key?(:edges),
       selection[:nodes],
       selection[:edges] == edges]
    end.to eq([true, 1, true, true, [1], true])
  end

  it 'can select nodes and get the selection' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      net.select_nodes([1, 3])
      selection = net.get_selected_nodes
      [net.is_a?(Vis::Network), created, selection]
    end.to eq([true, 1, [1, 3]])
  end

  it 'can select edges and get the selection' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      edges = net.get_connected_edges(1)
      net.select_edges(edges)
      selection = net.get_selected_edges
      [net.is_a?(Vis::Network), created, selection == edges]
    end.to eq([true, 1, true])
  end

  it 'can unselect all of a selection' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      edges = net.get_connected_edges(1)
      net.set_selection(nodes: [1], edges: edges)
      selection = net.get_selection
      net.unselect_all
      after_selection = net.get_selection
      [net.is_a?(Vis::Network), created,
       selection[:nodes],
       selection[:edges] == edges,
       after_selection[:nodes],
       after_selection[:edges]]
    end.to eq([true, 1, [1], true, [], []])
  end

  it 'gets the scale of the current viewport' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      scale = net.get_scale
      [net.is_a?(Vis::Network), created, scale]
    end.to eq([true, 1, 1.0])
  end

  it 'gets the view position' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      position = net.get_view_position
      [net.is_a?(Vis::Network), created,
       position[:x].is_a?(Integer),
       position[:y].is_a?(Integer)]
    end.to eq([true, 1, true, true])
  end

  it 'can call fit' do
    # not sure of a way to check, so we just call and make sure no exceptions is thrown
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      has_error = false
      begin
        net.fit
      rescue
        has_error = true
      end
      [net.is_a?(Vis::Network), created, has_error]
    end.to eq([true, 1, false])
  end

  it 'can focus on a node and releae it' do
    # no way to check if a node is focused?
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      has_error = false
      begin
        net.focus('3')
        net.release_node
      rescue
        has_error = true
      end
      [net.is_a?(Vis::Network), created, has_error]
    end.to eq([true, 1, false])
  end

  it 'can move the viewport' do
    # no way to check if a node is focused?
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      old_position = net.get_view_position
      net.move_to({position: {x: 50, y: 50}})
      new_position = net.get_view_position
      [net.is_a?(Vis::Network), created, old_position != new_position, new_position['x'], new_position['y']]
    end.to eq([true, 1, true, 50, 50])
  end

  it 'can get the options from a configurator' do
    # no way to check if a node is focused?
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
      created = dom_node.JS[:children].JS[:length]
      options = net.get_options_from_configurator
      [net.is_a?(Vis::Network), created, options.is_a?(Hash)]
    end.to eq([true, 1, true])
  end
end
