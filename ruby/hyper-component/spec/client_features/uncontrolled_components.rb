require 'spec_helper'

describe 'uncontrolled components initial value', js: true do
  it 'with default (text) INPUT tag' do
    mount 'TestComponent' do
      class TestComponent < HyperComponent
        render(INPUT, id: :input, init: 'some value')
      end
    end
    expect(find('#input').value).to eq('some value')
  end
  it 'with text INPUT tag' do
    mount 'TestComponent' do
      class TestComponent < HyperComponent
        render(INPUT, id: :input, type: :text, init: 'some value')
      end
    end
    expect(find('#input').value).to eq('some value')
  end
  it 'with TEXTAREA tag' do
    mount 'TestComponent' do
      class TestComponent < HyperComponent
        render(TEXTAREA, id: :input, init: 'some value')
      end
    end
    expect(find('#input').value).to eq('some value')
  end
  it 'with SELECT tag' do
    mount 'TestComponent' do
      class TestComponent < HyperComponent
        render(SELECT, id: :input, init: 'some value') do
          OPTION(value: 'wrong value')
          OPTION(id: :correct_option, value: 'some value')
          OPTION(value: 'other value')
        end
      end
    end
    expect(find('#input').value).to eq('some value')
    expect(find('#correct_option')).to be_selected
  end
  it 'with checkbox INPUT tag' do
    mount 'TestComponent' do
      class TestComponent < HyperComponent
        render(DIV) do
          INPUT(id: :input1, type: :checkbox, init: true)
          INPUT(id: :input2, type: :checkbox, init: false)
        end
      end
    end
    expect(find('#input1')).to be_checked
    expect(find('#input2')).not_to be_checked
  end
  it 'with radio INPUT tag' do
    mount 'TestComponent' do
      class TestComponent < HyperComponent
        render(DIV) do
          INPUT(id: :input1, type: :radio, init: true)
          INPUT(id: :input2, type: :radio, init: false)
        end
      end
    end
    expect(find('#input1')).to be_checked
    expect(find('#input2')).not_to be_checked
  end
end
