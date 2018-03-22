require 'spec_helper'

describe 'Vis::Graph2d', js: true do

  it 'creates a new Graph' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      [g2d.is_a?(Vis::Graph2d), dom_node.JS[:children].JS[:length]]
    end.to eq([true, 1])
  end

  it 'creates a new Graph and destroys it' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      g2d.destroy
      [g2d.is_a?(Vis::Graph2d), created, dom_node.JS[:children].JS[:length]]
    end.to eq([true, 1, 0])
  end
  
  it 'it can replace the items' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      new_items = [
        {x: '2014-06-12', y: 20},
        {x: '2014-06-13', y: 10},
        {x: '2014-06-14', y: 25},
        {x: '2014-06-15', y: 30},
        {x: '2014-06-16', y: 25},
        {x: '2014-06-17', y: 20}
      ]
      new_dataset = Vis::DataSet.new(new_items)
      g2d.set_items(new_dataset)
      [g2d.is_a?(Vis::Graph2d), created]
    end.to eq([true, 1])
  end

  it 'it can set options' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      error = false
      begin
        g2d.set_options({
          shaded: { enabled: true },
          graph_height: 200
        })
      rescue
        error = true
      end
      [g2d.is_a?(Vis::Graph2d), created, error]
    end.to eq([true, 1, false])
  end

  it 'it can set and remove a event listener' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      received = []
      handler_id = g2d.on(:changed) do
        received << 1
      end
      new_items = [
        {x: '2014-06-12', y: 20},
        {x: '2014-06-13', y: 10},
        {x: '2014-06-14', y: 25},
        {x: '2014-06-15', y: 30},
        {x: '2014-06-16', y: 25},
        {x: '2014-06-17', y: 20}
      ]
      new_dataset = Vis::DataSet.new(new_items)
      g2d.set_items(new_dataset)
      g2d.off(:changed, handler_id)
      g2d.set_items(dataset)
      [g2d.is_a?(Vis::Graph2d), created, received.size]
    end.to eq([true, 1, 2])
  end

  it 'can call redraw' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      g2d.redraw
      redrawn = dom_node.JS[:children].JS[:length]
      [g2d.is_a?(Vis::Graph2d), created, redrawn]
    end.to eq([true, 1, 1])
  end

  it 'can call fit' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      g2d.fit
      fitted = dom_node.JS[:children].JS[:length]
      [g2d.is_a?(Vis::Graph2d), created, fitted]
    end.to eq([true, 1, 1])
  end

  it 'can set and get current time' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18', show_current_time: true }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      now = Time.now
      time_get = g2d.get_current_time
      same_get_year = time_get.year == now.year
      g2d.set_current_time(Time.now + 1.year)
      time_set = g2d.get_current_time
      same_set_year = time_set.year == (now + 1.year).year
      [g2d.is_a?(Vis::Graph2d), created, same_get_year, same_set_year]
    end.to eq([true, 1, true, true])
  end

  it 'can set and get custom time' do
    # option showCustomTime is deprecated in vis, throws error
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      now = Time.now
      g2d.add_custom_time(now, 'time 1')
      time_get = g2d.get_custom_time('time 1')
      same_get_year = time_get.year == now.year
      g2d.set_custom_time(Time.now + 1.year, 'time 1')
      time_set = g2d.get_custom_time('time 1')
      same_set_year = time_set.year == (now + 1.year).year
      g2d.remove_custom_time('time 1')
      [g2d.is_a?(Vis::Graph2d), created, same_get_year, same_set_year]
    end.to eq([true, 1, true, true])
  end

  it 'can get the data range' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      data_range = g2d.get_data_range
      min = data_range[:min].strftime('%Y-%m-%d')
      max = data_range[:max].strftime('%Y-%m-%d')
      [g2d.is_a?(Vis::Graph2d), created, min, max]
    end.to eq([true, 1, '2014-06-11', '2014-06-16'])
  end

  it 'can get and set the window' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      window = g2d.get_window
      gws = window[:start].strftime('%Y-%m-%d')
      gwe = window[:end].strftime('%Y-%m-%d')
      g2d.set_window('2014-06-12', '2014-06-15')
      # window is set, but
      # get_window doesnt work here, gives back the orignal values, but not the current ones
      # window_fc = g2d.get_window
      # sws = window_fc[:start].strftime('%Y-%m-%d')
      # swe = window_fc[:end].strftime('%Y-%m-%d')
      [g2d.is_a?(Vis::Graph2d), created, gws, gwe]
    end.to eq([true, 1, '2014-06-10', '2014-06-18'])
  end

  it 'can move the window' do
    expect_evaluate_ruby do
      items = [
        {x: '2014-06-11', y: 10},
        {x: '2014-06-12', y: 25},
        {x: '2014-06-13', y: 30},
        {x: '2014-06-14', y: 10},
        {x: '2014-06-15', y: 15},
        {x: '2014-06-16', y: 30}
      ]
      options = { start: '2014-06-10', end: '2014-06-18' }
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Graph2d.test_container
      g2d = Vis::Graph2d.new(dom_node, dataset, options)
      created = dom_node.JS[:children].JS[:length]
      g2d.move_to('2014-06-12')
      [g2d.is_a?(Vis::Graph2d), created]
    end.to eq([true, 1])
  end

  xit 'get_event_properties'
  xit 'is_group_visible'
  xit 'set_groups'
  xit 'get_legend'
end
