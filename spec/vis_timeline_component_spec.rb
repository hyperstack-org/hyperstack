require 'spec_helper'

describe 'Hyperloop::Vis::Timeline::Component', js: true do

  it 'creates a component by using the mixin and renders it' do
    mount 'OuterComponent' do
      class VisComponent
        include Hyperloop::Vis::Timeline::Mixin

        render_with_dom_node do |dom_node, items|
          net = Vis::Timeline.new(dom_node, items)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([
            {id: 1, content: 'item 1', start: '2013-04-20'},
            {id: 2, content: 'item 2', start: '2013-04-14'},
            {id: 3, content: 'item 3', start: '2013-04-18'},
            {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
            {id: 5, content: 'item 5', start: '2013-04-25'},
            {id: 6, content: 'item 6', start: '2013-04-27'}
          ])
          DIV { VisComponent(items: data) }
        end
      end
    end
    expect(page.body).to include('class="vis-timeline')
  end

  it 'creates a component by inheriting and renders it' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Timeline::Component
        render_with_dom_node do |dom_node, items|
          net = Vis::Timeline.new(dom_node, items)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([
            {id: 1, content: 'item 1', start: '2013-04-20'},
            {id: 2, content: 'item 2', start: '2013-04-14'},
            {id: 3, content: 'item 3', start: '2013-04-18'},
            {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
            {id: 5, content: 'item 5', start: '2013-04-25'},
            {id: 6, content: 'item 6', start: '2013-04-27'}
          ])
          DIV { VisComponent(items: data) }
        end
      end
    end
    expect(page.body).to include('class="vis-timeline')
  end

  it 'actually passes the params to the component' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Timeline::Component
        def self.passed_data
          @@passed_data
        end
        def self.passed_options
          @@passed_options
        end
        render_with_dom_node do |dom_node, items, groups, options|
          @@passed_data = items
          @@passed_options = options
          net = Vis::Timeline.new(dom_node, items, options)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([
            {id: 1, content: 'item 1', start: '2013-04-20'},
            {id: 2, content: 'item 2', start: '2013-04-14'},
            {id: 3, content: 'item 3', start: '2013-04-18'},
            {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
            {id: 5, content: 'item 5', start: '2013-04-25'},
            {id: 6, content: 'item 6', start: '2013-04-27'}
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
