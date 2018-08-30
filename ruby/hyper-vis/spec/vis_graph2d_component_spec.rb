require 'spec_helper'

describe 'Hyperloop::Vis::Graph2d::Component', js: true do

  it 'creates a component by using the mixin and renders it' do
    mount 'OuterComponent' do
      class VisComponent
        include Hyperloop::Vis::Graph2d::Mixin

        render_with_dom_node do |dom_node, items|
          net = Vis::Graph2d.new(dom_node, items)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([
            {x: '2014-06-11', y: 10},
            {x: '2014-06-12', y: 25},
            {x: '2014-06-13', y: 30},
            {x: '2014-06-14', y: 10},
            {x: '2014-06-15', y: 15},
            {x: '2014-06-16', y: 30}
          ])
          DIV { VisComponent(items: data) }
        end
      end
    end
    expect(page.body).to include('class="vis-timeline')
  end

  it 'creates a component by inheriting and renders it' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Graph2d::Component
        render_with_dom_node do |dom_node, items|
          net = Vis::Graph2d.new(dom_node, items)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([
            {x: '2014-06-11', y: 10},
            {x: '2014-06-12', y: 25},
            {x: '2014-06-13', y: 30},
            {x: '2014-06-14', y: 10},
            {x: '2014-06-15', y: 15},
            {x: '2014-06-16', y: 30}
          ])
          DIV { VisComponent(items: data) }
        end
      end
    end
    expect(page.body).to include('class="vis-timeline')
  end

  it 'actually passes the params to the component' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Graph2d::Component
        def self.passed_data
          @@passed_data
        end
        def self.passed_options
          @@passed_options
        end
        render_with_dom_node do |dom_node, items, groups, options|
          @@passed_data = items
          @@passed_options = options
          net = Vis::Graph2d.new(dom_node, items, options)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([
            {x: '2014-06-11', y: 10},
            {x: '2014-06-12', y: 25},
            {x: '2014-06-13', y: 30},
            {x: '2014-06-14', y: 10},
            {x: '2014-06-15', y: 15},
            {x: '2014-06-16', y: 30}
          ])
          options = { align: 'left' }
          DIV { VisComponent(items: data, options: options)}
        end
      end
    end
    expect(page.body).to include('class="vis-timeline')
    expect_evaluate_ruby('VisComponent.passed_data.is_a?(Vis::DataSet)').to eq(true)
    expect_evaluate_ruby('VisComponent.passed_options.has_key?(:align)').to eq(true)
  end
end
