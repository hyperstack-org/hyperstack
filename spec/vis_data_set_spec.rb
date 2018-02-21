require 'spec_helper'

describe 'Vis::DataSet', js: true do
  it 'creates a empty DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new
      [dataset.is_a?(Vis::DataSet), dataset.size]
    end.to eq([true, 0])
  end

  it 'creates a DataSet with predefined data' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      [dataset.is_a?(Vis::DataSet), dataset.size]
    end.to eq([true, 2])
  end

  it 'createa a DataSet with options' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new(field_id: 'foo')
      [dataset.is_a?(Vis::DataSet), dataset.size]
    end.to eq([true, 0])
  end

  it 'createa a DataSet with predefined data and options' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{foo: 1, name: 'foo'}, {foo: 2, name: 'bar'}], field_id: 'foo')
      [dataset.is_a?(Vis::DataSet), dataset.size]
    end.to eq([true, 2])
  end

  it 'can add data to a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new
      dataset.add({id: 1, name: 'foo'})
      [dataset.is_a?(Vis::DataSet), dataset.size]
    end.to eq([true, 1])
  end

  it 'can add a array of data to a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new
      dataset.add([{foo: 1, name: 'foo'}, {foo: 2, name: 'bar'}])
      [dataset.is_a?(Vis::DataSet), dataset.size]
    end.to eq([true, 2])
  end

  it 'can iterate through a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      iterations = 0
      dataset.each { iterations += 1 }
      [dataset.is_a?(Vis::DataSet), dataset.size, iterations]
    end.to eq([true, 2, 2])
  end

  it 'can get data by id from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      data = dataset.get(2)
      [dataset.is_a?(Vis::DataSet), dataset.size, data[:name]]
    end.to eq([true, 2, 'bar'])
  end

  it 'can get an array of data by ids from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      data = dataset.get([1, 2])
      [dataset.is_a?(Vis::DataSet), dataset.size, data.size, data[0][:name], data[1][:name]]
    end.to eq([true, 2, 2, 'foo', 'bar'])
  end

  it 'can get a filtered array of data by ids from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      data = dataset.get([1, 2], filter: proc { |item| item[:name] == 'foo' })
      [dataset.is_a?(Vis::DataSet), dataset.size, data.size, data[0][:name]]
    end.to eq([true, 2, 1, 'foo'])
  end

  it 'can get data by id with [] from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      data = dataset[2]
      [dataset.is_a?(Vis::DataSet), dataset.size, data[:name]]
    end.to eq([true, 2, 'bar'])
  end

  it 'can get all ids from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      data = dataset.get_ids
      [dataset.is_a?(Vis::DataSet), dataset.size, [1, 2]]
    end.to eq([true, 2, [1, 2]])
  end

  it 'can map a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}])
      data = dataset.map { |i| i[:name] }
      [dataset.is_a?(Vis::DataSet), dataset.size, data]
    end.to eq([true, 2, ['foo', 'bar']])
  end

  it 'can get the item with max value of a field of a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      data = dataset.max(:height)
      [dataset.is_a?(Vis::DataSet), dataset.size, data[:height]]
    end.to eq([true, 2, 100])
  end

  it 'can get the item with min value of a field of a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      data = dataset.min(:height)
      [dataset.is_a?(Vis::DataSet), dataset.size, data[:height]]
    end.to eq([true, 2, 50])
  end

  it 'can register a on event handler for a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      items = []
      dataset.on(:update) { |event, properties, sender_id| items << properties[:items] }
      dataset.update({id: 2, height: 200})
      items
    end.to eq([[2]])
  end
  
  it 'can register a on event handler for a DataSet and remove it again' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      items = []
      eh_id = dataset.on(:update) { |event, properties, sender_id| items << properties[:items] } 
      dataset.update({id: 2, height: 200})
      dataset.off(:update, eh_id)
      dataset.update({id: 1, height: 400})
      items
    end.to eq([[2]])
  end

  it 'can remove a item by id from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      data = dataset.remove(1)
      [dataset.is_a?(Vis::DataSet), dataset.size, data]
    end.to eq([true, 1, [1]])
  end

  it 'can remove multiple items by ids from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      data = dataset.remove([1,2])
      [dataset.is_a?(Vis::DataSet), dataset.size, data]
    end.to eq([true, 0, [1, 2]])
  end

  it 'can remove a item by itself from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      data = dataset.remove({id: 2, height: 100})
      [dataset.is_a?(Vis::DataSet), dataset.size, data]
    end.to eq([true, 1, [2]])
  end

  it 'can update a item from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      data = dataset.update({id: 2, height: 200})
      height = dataset[2][:height]
      [dataset.is_a?(Vis::DataSet), dataset.size, data, height]
    end.to eq([true, 2, [2], 200])
  end

  it 'can update multiple itema from a DataSet' do
    expect_evaluate_ruby do
      dataset = Vis::DataSet.new([{id: 1, height: 50}, {id: 2, height: 100}])
      data = dataset.update([{id: 1, height: 75}, {id: 2, height: 200}])
      heights = [dataset[1][:height], dataset[2][:height]]
      [dataset.is_a?(Vis::DataSet), dataset.size, data, heights]
    end.to eq([true, 2, [1, 2], [75, 200]])
  end
end