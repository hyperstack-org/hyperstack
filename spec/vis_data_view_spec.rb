require 'spec_helper'

describe 'Vis::DataView', js: true do
  it 'creates a DataView with a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset)
      [dataview.is_a?(Vis::DataView), dataview.size]
    end.to eq([true, 3])
  end

  it 'creates a filtered DataView with a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      [dataview.is_a?(Vis::DataView), dataview.size]
    end.to eq([true, 2])
  end

  it 'it can get a item by id from a DataView' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      item = dataview.get(2)
      [dataview.is_a?(Vis::DataView), dataview.size, item[:name]]
    end.to eq([true, 2, 'bar'])
  end

  it 'it cannot get a filtered item by id from a DataView' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      item = dataview.get(1)
      [dataview.is_a?(Vis::DataView), dataview.size, item]
    end.to eq([true, 2, nil])
  end

  it 'it gets a filtered array of items by id from a DataView' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      items = dataview.get([1,2,3])
      [dataview.is_a?(Vis::DataView), dataview.size, items.size]
    end.to eq([true, 2, 2])
  end

  it 'it gets the DataSet from a DataView' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      set = dataview.get_data_set
      [dataview.is_a?(Vis::DataView), dataview.size, set.is_a?(Vis::DataSet), set.size]
    end.to eq([true, 2, true, 3])
  end

  it 'it gets the filtered list of ids from a DataView' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      ids = dataview.get_ids
      [dataview.is_a?(Vis::DataView), dataview.size, ids]
    end.to eq([true, 2, [2, 3]])
  end

  it 'can register a on event handler for a DataVet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      items = []
      dataview.on(:update) { |event, properties, sender_id| items << properties[:items] }
      dataset.update({id: 2, name: 'pub'})
      items
    end.to eq([[2]])
  end
  
  it 'can register a on event handler for a DataSet and remove it again' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| ['bar', 'pub'].include?(item[:name]) })
      items = []
      eh_id = dataview.on(:update) { |event, properties, sender_id| items << properties[:items] } 
      dataset.update({id: 2, name: 'pub'})
      dataview.off(:update, eh_id)
      dataset.update({id: 2, name: 'bar'})
      items
    end.to eq([[2]])
  end

  it 'it can refresh a DataView' do
    expect_evaluate_ruby do
      array = ['bar', 'pub']
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| array.include?(item[:name]) })
      size_before = dataview.size
      array = ['bar', 'pub', 'foo']
      dataview.refresh
      [dataview.is_a?(Vis::DataView), size_before, dataview.size]
    end.to eq([true, 2, 3])
  end

  it 'it can set a new DataSaet for the DataView' do
    expect_evaluate_ruby do
      array = ['bar', 'pub']
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
      dataview = Vis::DataView.new(dataset, filter: proc { |item| array.include?(item[:name]) })
      size_before = dataview.size
      dataset2 = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      dataview.set_data(dataset2)
      [dataview.is_a?(Vis::DataView), size_before, dataview.size]
    end.to eq([true, 2, 1])
  end
end