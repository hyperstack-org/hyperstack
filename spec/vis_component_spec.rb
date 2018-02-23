require 'spec_helper'

describe 'Hyperloop::Vis::Component', js: true do

  it 'creates a component by using the mixin and renders it' do
    mount 'OuterComponent' do
      class VisComponent
        include Hyperloop::Vis::Mixin

        render_with_dom_node do |dom_node, data|
          net = Vis::Network.new(dom_node, data)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(data: data)}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end

  it 'creates a component by inheriting and renders it' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Component
        render_with_dom_node do |dom_node, data|
          net = Vis::Network.new(dom_node, data)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(data: data)}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end
end
