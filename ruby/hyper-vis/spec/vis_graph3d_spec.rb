require 'spec_helper'

describe 'Vis::Graph3d', js: true do

  it 'creates a new Graph with options' do
    expect_evaluate_ruby do
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
      dom_node = Vis::Graph3d.test_container
      g3d = Vis::Graph3d.new(dom_node, dataset, options)
      [g3d.is_a?(Vis::Graph3d), dom_node.JS[:children].JS[:length]]
    end.to eq([true, 1])
  end
  
  it 'it can replace the data' do
    expect_evaluate_ruby do
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
      dom_node = Vis::Graph3d.test_container
      g3d = Vis::Graph3d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      new_dataset = Vis::DataSet.new
      (0...axis_max).step(axis_step) do |x|
        (0...axis_max).step(axis_step) do |y|
          value = Math.cos(x/50) * Math.sin(y/50) * 50 + 50
          new_dataset.add(x: x, y: y, z: value, style: value)
        end
      end
      g3d.set_data(new_dataset)
      [g3d.is_a?(Vis::Graph3d), created]
    end.to eq([true, 1])
  end

  it 'it can set options' do
    expect_evaluate_ruby do
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
      dom_node = Vis::Graph3d.test_container
      g3d = Vis::Graph3d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      error = false
      begin
        g3d.set_options({
          width:  '500px',
          height: '500px',
          style: 'surface',
          show_perspective: true,
          show_grid: true,
          show_shadow: true,
          keep_aspect_ratio: true,
          vertical_ratio: 0.5
        })
      rescue
        error = true
      end
      [g3d.is_a?(Vis::Graph3d), created, error]
    end.to eq([true, 1, false])
  end

  xit 'it can set a event listener' do
    # needs simulated user input
    expect_evaluate_ruby do
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
      dom_node = Vis::Graph3d.test_container
      g3d = Vis::Graph3d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      received = []
      g3d.on(:camera_position_change) do |info|
        received << info
        `console.log('received', info)`
      end
      [g3d.is_a?(Vis::Graph3d), created, received.size]
    end.to eq([true, 1, 1])
  end

  it 'can call redraw' do
    expect_evaluate_ruby do
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
      dom_node = Vis::Graph3d.test_container
      g3d = Vis::Graph3d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      g3d.redraw
      redrawn = dom_node.JS[:children].JS[:length]
      [g3d.is_a?(Vis::Graph3d), created, redrawn]
    end.to eq([true, 1, 1])
  end

  it 'can set the size' do
    expect_evaluate_ruby do
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
      dom_node = Vis::Graph3d.test_container
      g3d = Vis::Graph3d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      g3d.set_size('400px', '300px')
      dom_node.JS.querySelector('canvas')
      [g3d.is_a?(Vis::Graph3d), created]
    end.to eq([true, 1])
  end

  it 'can set and get the camera position' do
    expect_evaluate_ruby do
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
      dom_node = Vis::Graph3d.test_container
      g3d = Vis::Graph3d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      position = g3d.get_camera_position
      new_position = position.dup
      new_position[:distance] = new_position[:distance] + 1
      g3d.set_camera_position(new_position)
      final_position = g3d.get_camera_position
      [g3d.is_a?(Vis::Graph3d), created, final_position[:distance] == new_position[:distance]]
    end.to eq([true, 1, true])
  end

  xit 'animation_start'
  xit 'animation_stop'
end
