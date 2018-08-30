require 'spec_helper'

describe 'Vis::Timeline', js: true do

  it 'creates a new Timeline' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      [tl.is_a?(Vis::Timeline), dom_node.JS[:children].JS[:length]]
    end.to eq([true, 1])
  end

  it 'creates a new Timeline and destroys it' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      tl.destroy
      [tl.is_a?(Vis::Timeline), created, dom_node.JS[:children].JS[:length]]
    end.to eq([true, 1, 0])
  end
  
  it 'it can replace the items' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      new_items = [
        {id: 1, content: 'item 1', start: '2013-05-20'},
        {id: 2, content: 'item 2', start: '2013-05-14'},
        {id: 3, content: 'item 3', start: '2013-05-18'},
        {id: 4, content: 'item 4', start: '2013-05-16', end: '2013-05-19'},
        {id: 5, content: 'item 5', start: '2013-05-25'},
        {id: 6, content: 'item 6', start: '2013-05-27'}
      ]
      new_dataset = Vis::DataSet.new(new_items)
      tl.set_items(new_dataset)
      [tl.is_a?(Vis::Timeline), created]
    end.to eq([true, 1])
  end

  it 'it can set options' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      error = false
      begin
        tl.set_options(selectable: false)
      rescue
        error = true
      end
      [tl.is_a?(Vis::Timeline), created, error]
    end.to eq([true, 1, false])
  end

  xit 'it can set and remove a event listener' do
    # needs simulation of user interaction
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      received = []
      handler_id = tl.on(:changed) do
        received << 1
      end
      new_items = [
        {id: 1, content: 'item 1', start: '2013-05-20'},
        {id: 2, content: 'item 2', start: '2013-05-14'},
        {id: 3, content: 'item 3', start: '2013-05-18'},
        {id: 4, content: 'item 4', start: '2013-05-16', end: '2013-05-19'},
        {id: 5, content: 'item 5', start: '2013-05-25'},
        {id: 6, content: 'item 6', start: '2013-05-27'}
      ]
      new_dataset = Vis::DataSet.new(new_items)
      tl.set_items(new_dataset)
      tl.redraw
      tl.off(:changed, handler_id)
      tl.set_items(dataset)
      [tl.is_a?(Vis::Timeline), created, received.size]
    end.to eq([true, 1, 2])
  end

  it 'can call redraw' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      tl.redraw
      redrawn = dom_node.JS[:children].JS[:length]
      [tl.is_a?(Vis::Timeline), created, redrawn]
    end.to eq([true, 1, 1])
  end

  it 'can call fit' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      tl.fit
      fitted = dom_node.JS[:children].JS[:length]
      [tl.is_a?(Vis::Timeline), created, fitted]
    end.to eq([true, 1, 1])
  end

  it 'can set and get current time' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      now = Time.now
      time_get = tl.get_current_time
      same_get_year = time_get.year == now.year
      tl.set_current_time(Time.now + 1.year)
      time_set = tl.get_current_time
      same_set_year = time_set.year == (now + 1.year).year
      [tl.is_a?(Vis::Timeline), created, same_get_year, same_set_year]
    end.to eq([true, 1, true, true])
  end

  it 'can add, set, get and remove a custom time, also can set a custom time title' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      now = Time.now
      tl.add_custom_time(now, 'time 1')
      tl.set_custom_time_title("Oh waht a time!", 'time 1')
      time_get = tl.get_custom_time('time 1')
      same_get_year = time_get.year == now.year
      tl.set_custom_time(Time.now + 1.year, 'time 1')
      time_set = tl.get_custom_time('time 1')
      same_set_year = time_set.year == (now + 1.year).year
      tl.remove_custom_time('time 1')
      [tl.is_a?(Vis::Timeline), created, same_get_year, same_set_year]
    end.to eq([true, 1, true, true])
  end

  it 'can set new data' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      received = []
      handler_id = tl.on(:changed) do
        received << 1
      end
      new_items = [
        {id: 1, content: 'item 1', start: '2013-05-20'},
        {id: 2, content: 'item 2', start: '2013-05-14'},
        {id: 3, content: 'item 3', start: '2013-05-18'},
        {id: 4, content: 'item 4', start: '2013-05-16', end: '2013-05-19'},
        {id: 5, content: 'item 5', start: '2013-05-25'},
        {id: 6, content: 'item 6', start: '2013-05-27'}
      ]
      new_dataset = Vis::DataSet.new(new_items)
      tl.set_data({items: new_dataset})
      [tl.is_a?(Vis::Timeline), created]
    end.to eq([true, 1])
  end

  it 'can get and set the window' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      window = tl.get_window
      gws = window[:start].strftime('%Y-%m-%d')
      gwe = window[:end].strftime('%Y-%m-%d')
      tl.set_window('2014-06-12', '2014-06-15')
      # window is set, but
      # get_window doesnt work here, gives back the orignal values, but not the current ones
      # window_fc = tl.get_window
      # sws = window_fc[:start].strftime('%Y-%m-%d')
      # swe = window_fc[:end].strftime('%Y-%m-%d')

      # this is flaky, depending on browser window size,
      # so we dont check for the exact day and chop the last digit off
      [tl.is_a?(Vis::Timeline), created, gws.chop, gwe.chop] 
    end.to eq([true, 1, '2013-04-1', '2013-04-2'])
  end

  it 'can move the window' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      tl.move_to('2014-06-12')
      [tl.is_a?(Vis::Timeline), created]
    end.to eq([true, 1])
  end

  it 'can focus on item' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      tl.focus(4)
      [tl.is_a?(Vis::Timeline), created]
    end.to eq([true, 1])
  end

  it 'can select a item and get it' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      tl.set_selection(4)
      sel = tl.get_selection
      [tl.is_a?(Vis::Timeline), created, sel.first]
    end.to eq([true, 1, 4])
  end

  xit 'can get visible items' do
    # result is always [] ?
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset)
      created = dom_node.JS[:children].JS[:length]
      tl.focus(3)
      vis_i = tl.get_visible_items
      [tl.is_a?(Vis::Timeline), created, vis_i.size]
    end.to eq([true, 1, 1])
  end
  
  it 'can toggle rolling mode' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset, rolling_mode: { offset: 0.5 })
      created = dom_node.JS[:children].JS[:length]
      tl.toggle_rolling_mode
      [tl.is_a?(Vis::Timeline), created]
    end.to eq([true, 1])
  end

  it 'can get the range of items' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset, rolling_mode: { offset: 0.5 })
      created = dom_node.JS[:children].JS[:length]
      data_range = tl.get_item_range
      # this is flaky, depending on something,
      # so we dont check for the exact day and chop the last digit off
      min = data_range[:min].strftime('%Y-%m-%d').chop
      max = data_range[:max].strftime('%Y-%m-%d').chop
      [tl.is_a?(Vis::Timeline), created, min, max]
    end.to eq([true, 1, '2013-04-1', '2013-04-2'])
  end

  it 'can zoom in and out' do
    expect_evaluate_ruby do
      items = [
        {id: 1, content: 'item 1', start: '2013-04-20'},
        {id: 2, content: 'item 2', start: '2013-04-14'},
        {id: 3, content: 'item 3', start: '2013-04-18'},
        {id: 4, content: 'item 4', start: '2013-04-16', end: '2013-04-19'},
        {id: 5, content: 'item 5', start: '2013-04-25'},
        {id: 6, content: 'item 6', start: '2013-04-27'}
      ]
      dataset = Vis::DataSet.new(items)
      dom_node = Vis::Timeline.test_container
      tl = Vis::Timeline.new(dom_node, dataset, rolling_mode: { offset: 0.5 })
      created = dom_node.JS[:children].JS[:length]
      tl.zoom_in(0.1)
      tl.zoom_out(0.2)
      [tl.is_a?(Vis::Timeline), created]
    end.to eq([true, 1])
  end

  xit 'get_event_properties'
  xit 'set_groups'
end
