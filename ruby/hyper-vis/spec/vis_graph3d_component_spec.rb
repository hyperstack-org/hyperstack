require 'spec_helper'

describe 'Hyperloop::Vis::Graph3d::Component', js: true do

  it 'creates a component by using the mixin and renders it' do
    mount 'OuterComponent' do
      class VisComponent
        include Hyperloop::Vis::Graph3d::Mixin

        render_with_dom_node do |dom_node, data, options|
          net = Vis::Graph3d.new(dom_node, data, options)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          options = {
            width:  '600px',
            height: '600px',
            style: 'surface',
            show_perspective: true,
            show_grid: true,
            show_shadow: false,
            keep_aspect_ratio: true,
            vertical_ratio: 0.5
          }
          dataset = Vis::DataSet.new
          steps = 50  # number of datapoints will be steps*steps
          axis_max = 314
          axis_step = axis_max / steps
          (0...axis_max).step(axis_step) do |x|
            (0...axis_max).step(axis_step) do |y|
              value = Math.sin(x/50) * Math.cos(y/50) * 50 + 50
              dataset.add(x: x, y: y, z: value, style: value)
            end
          end
          DIV { VisComponent(vis_data: dataset, options: options)}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end

  it 'creates a component by inheriting and renders it' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Graph3d::Component
        render_with_dom_node do |dom_node, data, options|
          net = Vis::Graph3d.new(dom_node, data, options)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          options = {
            width:  '600px',
            height: '600px',
            style: 'surface',
            show_perspective: true,
            show_grid: true,
            show_shadow: false,
            keep_aspect_ratio: true,
            vertical_ratio: 0.5
          }
          dataset = Vis::DataSet.new
          steps = 50  # number of datapoints will be steps*steps
          axis_max = 314
          axis_step = axis_max / steps
          (0...axis_max).step(axis_step) do |x|
            (0...axis_max).step(axis_step) do |y|
              value = Math.sin(x/50) * Math.cos(y/50) * 50 + 50
              dataset.add(x: x, y: y, z: value, style: value)
            end
          end
          DIV { VisComponent(vis_data: dataset, options: options)}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end

  it 'actually passes the params to the component' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Graph3d::Component
        def self.passed_data
          @@passed_data
        end
        def self.passed_options
          @@passed_options
        end
        render_with_dom_node do |dom_node, data, options|
          @@passed_data = data
          @@passed_options = options
          net = Vis::Graph3d.new(dom_node, data, options)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          options = {
            width:  '600px',
            height: '600px',
            style: 'surface',
            show_perspective: true,
            show_grid: true,
            show_shadow: false,
            keep_aspect_ratio: true,
            vertical_ratio: 0.5
          }
          dataset = Vis::DataSet.new
          steps = 50  # number of datapoints will be steps*steps
          axis_max = 314
          axis_step = axis_max / steps
          (0...axis_max).step(axis_step) do |x|
            (0...axis_max).step(axis_step) do |y|
              value = Math.sin(x/50) * Math.cos(y/50) * 50 + 50
              dataset.add(x: x, y: y, z: value, style: value)
            end
          end
          DIV { VisComponent(vis_data: dataset, options: options)}
        end
      end
    end
    expect(page.body).to include('<canvas')
    expect_evaluate_ruby('VisComponent.passed_data.is_a?(Vis::DataSet)').to eq(true)
    expect_evaluate_ruby('VisComponent.passed_options.has_key?(:show_shadow)').to eq(true)
  end
end
