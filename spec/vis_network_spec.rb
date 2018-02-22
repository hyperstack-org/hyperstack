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
  
  xit 'setData'
  xit 'setOptions'
  xit 'on'
  xit 'off'
  xit 'once'

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

  xit 'cluster'
  xit 'clusterByConnection'
  xit 'clusterByHubsize'
  xit 'clusterOutliers'
  xit 'findNode'
  xit 'getClusterEdges'
  xit 'getBaseEdges'
  xit 'updateEdge'
  xit 'updateClusteredNode'
  xit 'isCluster'
  xit 'getNodesInCluster'
  xit 'openCluster'

  it 'can get the seed' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      seed = net.get_seed
      [net.is_a?(Vis::Network), created, seed.is_a?(Integer)]
    end.to eq([true, 1, true])
  end

  # use callback method in options for the following
  xit 'enableEditMode'
  xit 'disableEditMode'
  xit 'addNodeMode'
  xit 'editNode'
  xit 'addEdgeMode'
  xit 'editEdgeMode'
  xit 'deleteSelection'

  it 'can get the positions of nodes' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      positions = net.get_positions(['1', '2'])
      [net.is_a?(Vis::Network), created, positions.size, positions['1']['x'].is_a?(Integer)]
    end.to eq([true, 1, 2, true])
  end

  it 'can store the positions of nodes' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
      created = dom_node.JS[:children].JS[:length]
      net.store_positions
      item = dataset.get(1)
      [net.is_a?(Vis::Network), created, item.has_key?(:x), item[:x].is_a?(Integer)]
    end.to eq([true, 1, true, true])
  end

  it 'can move a node' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dom_node = Vis::Network.test_container
      net = Vis::Network.new(dom_node, {nodes: dataset})
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
end
