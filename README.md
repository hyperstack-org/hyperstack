# hyper-vis

A Opal Ruby wraper for (Vis.js)[visjs.org] with a Ruby-Hyperloop Component.
Currently supports the complete API for:
- Vis Dataset
- Vis Dataview
- Vis Network

### Installation
for a rails app:
```
gem 'hyper-vis'
```
and `bundle update`
hyper-vis depends on `hyper-component` from (ruby-hyperloop)[http://ruby-hyperloop.org]

vis.js is automatically imported. If you use webpacker, you may need to cancel the import in your config/intializers/hyperloop.rb
```
  config.cancel_import 'vis/source/vis.js'
```
The wrapper expects a global `vis' (not `Vis`) to be availabe in javascript. 
stylesheets are includes in 'vis/source/vis.css', images are there too.

### Usage

#### The Vis part
```
dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
edge_dataset = Vis::DataSet.new([{from: 1, to: 2}, {from: 2, to: 3}])
dom_node = Vis::Network.test_container
net = Vis::Network.new(dom_node, {nodes: dataset, edges: edge_dataset})
xy = net.canvas_to_dom({x: 10, y: 10})
```
#### The Component part
The Component takes care about all the things necessary to make Vis.js play nice with React.
The Component also provides a helper to access the document.
Vis::Network can be used within the render_with_dom_node.
```
class MyVisNetworkComponent
  include Hyperloop::Vis::Network::Mixin

  render_with_dom_node do |dom_node, data, options|

    net = Vis::Network.new(dom_node, data, options)

    canvas = document.JS.querySelector('canvas')
  end
end

class AOuterComponent < Hyperloop::Component
  render do
    received_data = []

    options = { manipulation: {
        edit_node: proc { |node_data, callback| received_data << node_data }
      }}

    data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
    
    DIV { MyVisNetworkComponent(vis_data: data, otions: options)}
  end
end
```