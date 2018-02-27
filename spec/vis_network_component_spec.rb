require 'spec_helper'

describe 'Hyperloop::Vis::Component', js: true do

  it 'creates a component by using the mixin and renders it' do
    mount 'OuterComponent' do
      class VisComponent
        include Hyperloop::Vis::Network::Mixin

        render_with_dom_node do |dom_node, data|
          net = Vis::Network.new(dom_node, data)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(vis_data: {nodes: data})}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end

  it 'creates a component by inheriting and renders it' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Network::Component
        render_with_dom_node do |dom_node, data|
          net = Vis::Network.new(dom_node, data)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(vis_data: {nodes: data})}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end

  it 'actually passes the params to the component' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Network::Component
        def self.passed_data
          @@passed_data
        end
        def self.passed_options
          @@passed_options
        end
        render_with_dom_node do |dom_node, data, options|
          @@passed_data = data
          @@passed_options = options
          net = Vis::Network.new(dom_node, data, options)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          options = {
            :auto_resize => true,
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
          }
          DIV { VisComponent(vis_data: {nodes: data}, options: options)}
        end
      end
    end
    expect(page.body).to include('<canvas')
    expect_evaluate_ruby('VisComponent.passed_data.has_key?(:nodes)').to eq(true)
    expect_evaluate_ruby('VisComponent.passed_options.has_key?(:auto_resize)').to eq(true)
  end

  it 'can call a event_handler callback from render_with_dom_node' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Network::Component

        def self.received_calls
          @@recc ||= []
          @@recc
        end

        def test_handler_method(arg)
          @@recc ||= []
          @@recc << arg
        end

        render_with_dom_node do |dom_node, data|
          net = Vis::Network.new(dom_node, data)
          net.on(:resize) do |coords|
            test_handler_method(coords)
          end
          net.set_size(100, 100)
        end
      end

      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(vis_data: {nodes: data})}
        end
      end
    end
    expect(page.body).to include('<canvas')
    expect_evaluate_ruby('VisComponent.received_calls.size').to eq(1)
  end
end
