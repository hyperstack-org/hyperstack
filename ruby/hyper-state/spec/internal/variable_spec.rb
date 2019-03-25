require 'spec_helper'

describe Hyperstack::Internal::State::Variable do
  it 'will mutate and observe an object, name pair' do
    observer = double('observer')
    object =   double('object')
    value =    double('value')

    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).once do |mapped_object|
      @mapped_object = mapped_object
    end
    expect(subject.set(object, :name, value)).to be(value)
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(@mapped_object).and_call_original
    Hyperstack::Internal::State::Mapper.observing(observer, false, false, true) do
      expect(subject.get(object, :name)).to be(value)
    end
    expect(subject.observed?(object, :name)).to be_truthy
  end
end
