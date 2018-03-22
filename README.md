# hyper-vis

A [Opal](http://opalrb.com) Ruby wrapper for [Vis.js](http://visjs.org) with a [Ruby-Hyperloop](http://ruby-hyperloop.org) Component.
Implements the complete API for:
- [Vis Dataset](http://visjs.org/docs/data/dataset.html)
- [Vis Dataview](http://visjs.org/docs/data/dataview.html)
- [Vis Graph2d](http://visjs.org/docs/graph2d/)
- [Vis Graph3d](http://visjs.org/docs/graph3d/), wip
- [Vis Network](http://visjs.org/docs/network/)
- [Vis Timeline](http://visjs.org/docs/timeline/), wip

Includes vis.js version 4.21.0

## Demo

Reactive hyper-vis in action:

[![Reactivity Demo](http://img.youtube.com/vi/fPSpESBbeMQ/0.jpg)](http://www.youtube.com/watch?v=fPSpESBbeMQ "Reactivity Demo")

## Quality
[![Build Status](https://semaphoreci.com/api/v1/janbiedermann/hyper-vis/branches/master/shields_badge.svg)](https://semaphoreci.com/janbiedermann/hyper-vis)
[![GitHub issues](https://img.shields.io/github/issues/janbiedermann/hyper-vis.svg)](https://github.com/janbiedermann/hyper-vis/issues)
[![Percentage of issues still open](http://isitmaintained.com/badge/open/janbiedermann/hyper-vis.svg)](http://isitmaintained.com/project/janbiedermann/hyper-vis "Percentage of issues still open")
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/janbiedermann/hyper-vis.svg)](http://isitmaintained.com/project/janbiedermann/hyper-vis "Average time to resolve an issue")
[![Pending Pull-Requests](http://githubbadges.herokuapp.com/janbiedermann/hyper-vis/pulls.svg)](https://github.com/janbiedermann/hyper-vis/pulls)

#### Tests
```
Finished in 1 minute 58.6 seconds (files took 2.75 seconds to load)
93 examples, 0 failures, 8 pending
```
#### To run Tests
Clone repo, then:
```bash
bundle update
cd spec/test_app
bundle update
cd ../..
bundle exec rspec
```

## Installation
for a Rails app:
```ruby
gem 'hyper-vis'
```
and `bundle update`.

hyper-vis depends on `hyper-component` from Ruby-Hyperloop but can be used without it.

vis.js is automatically imported for Ruby-Hyperloop. If you get vis.js with webpacker, you may need to cancel the import in your config/intializers/hyperloop.rb
```ruby
  config.cancel_import 'vis/source/vis.js'
```
The wrapper expects a global `vis` (not `Vis`) to be availabe in javascript.
For Vis to function as expected the stylesheets must be included.
For a Rails app, the asset path is automatically added. 
In your `application.css` add:
```
  *= require vis.css
```
For other frameworks vis.js, stylesheets and images are available in the gems `lib/vis/source/` directory.

## Usage

The wrapper follows vis 1 to 1, conforming to ruby standards, instead of `setSize` in javascript, you would use `set_size`. Also see specs in the `specs` directory for usage or the vis documentation (linked above).
All arguments or return values are 'rubyfied' as much as possible, so you can just use ruby.

#### The Vis part
```ruby
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
```ruby
class MyVisNetworkComponent
  include Hyperloop::Vis::Network::Mixin

  # the component automatically calls the render_with_dom_node block every
  # time new data or options are received

  # however
  # setting automatic_refresh false turns that off ...
  # (default is true, so this is optional):
  automatic_refresh false

  # ... and with automatic_refresh false refresh can
  # be handled in the before_receive_props callback
  # for example (this is also optional):
  before_receive_props do |new_props|
    if new_props[:vis_data] != @data
      @net.set_data(new_props[:vis_data])
    end
  end

  render_with_dom_node do |dom_node, data, options|
    # its important to use the data as passed in as 'data' argument
    # to get the latests passed data for each new render
    @net = Vis::Network.new(dom_node, data, options)

    # save data for later or usage, for example
    # in before_receive_props for comparison
    @data = data

    # example of using the document helper
    canvas = document.JS.querySelector('canvas')
  end
end

class AOuterComponent < Hyperloop::Component
  render do
    received_data = []

    # example of using a callback in the options
    options = { manipulation: {
        edit_node: proc { |node_data, callback| received_data << node_data }
      }}

    # initialize a dataset
    data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
    
    # call the component
    DIV { MyVisNetworkComponent(vis_data: data, otions: options)}
  end
end
```
