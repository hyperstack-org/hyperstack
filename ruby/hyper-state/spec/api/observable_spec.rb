require 'spec_helper'

# Just checks to make sure all methods are available when either subclassing or including

describe Hyperstack::State::Observable do
  class Store
    include Hyperstack::State::Observable
  end
  let(:store) { Store.new }

  context 'observe instance method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
      store.instance_eval { @var = 12 }
      expect(store.instance_eval { observe { @var } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
      store.instance_eval { observe }
    end
  end

  context 'mutate instance method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
      expect(store.instance_eval { mutate { @var = 12 } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
      store.instance_eval { mutate }
    end
  end

  it 'the toggle instance method reverses the instance variable value and mutates' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
    expect(store.toggle(:var) ).to be_truthy
    expect(store.instance_eval { @var }).to be_truthy
  end

  context 'set instance method' do
    it "will mutate if the instance variable begins with a lower case letter" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
      [123].each(&store.set(:var))
      expect(store.instance_variable_get(:@var)).to eq(123)
    end
    it "will not mutate if the instance variable does not begin with a lower case letter" do
      expect(Hyperstack::Internal::State::Mapper).not_to receive(:mutated!).with(store)
      [123].each(&store.set(:Var))
      expect(store.instance_variable_get(:@Var)).to eq(123)
      [123].each(&store.set(:_var))
      expect(store.instance_variable_get(:@_var)).to eq(123)
    end
  end

  context 'observe class method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
      Store.instance_eval { @var = 12 }
      expect(Store.instance_eval { observe { @var } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
      Store.instance_eval { observe }
    end
  end

  context 'mutate class method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
      expect(Store.instance_eval { mutate { @var = 12 } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
      Store.instance_eval { mutate }
    end
  end

  it 'the toggle class method reverses the instance variable value and mutates' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
    expect(Store.toggle(:var) ).to be_truthy
    expect(Store.instance_eval { @var }).to be_truthy
  end

  context 'set class method' do
    it "will mutate if the instance variable begins with a lower case letter" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
      [123].each(&Store.set(:var))
      expect(Store.instance_variable_get(:@var)).to eq(123)
    end
    it "will not mutate if the instance variable does not begin with a lower case letter" do
      expect(Hyperstack::Internal::State::Mapper).not_to receive(:mutated!).with(Store)
      [123].each(&Store.set(:Var))
      expect(Store.instance_variable_get(:@Var)).to eq(123)
      [123].each(&Store.set(:_var))
      expect(Store.instance_variable_get(:@_var)).to eq(123)
    end
  end

  it 'observer instance method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
    Store.observer(:read_state) { @state }
    store.instance_eval { @state = 123 }
    expect(store.read_state).to eq(123)
  end

  it 'mutator instance method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
    Store.mutator(:write_state) { @state = 987 }
    expect(store.write_state).to eq(987)
    expect(store.instance_eval { @state }).to eq(987)
  end

  it 'state_accessor instance method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
    Store.state_accessor(:state)
    store.state = 777
    expect(store.state).to eq(777)
    expect(store.instance_eval { @state }).to eq(777)
  end

  it 'state_reader instance method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
    Store.state_reader(:state)
    store.instance_eval { @state = 999 }
    expect(store.state).to eq(999)
  end

  it 'state_writer instance method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
    Store.state_accessor(:state)
    store.state = 777
    expect(store.instance_eval { @state }).to eq(777)
  end

  it 'observer class method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
    Store.singleton_class.observer(:read_state) { @state }
    Store.instance_eval { @state = 123 }
    expect(Store.read_state).to eq(123)
  end

  it 'mutator class method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
    Store.singleton_class.mutator(:write_state) { @state = 987 }
    expect(Store.write_state).to eq(987)
    expect(Store.instance_eval { @state }).to eq(987)
  end

  it 'state_accessor class method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
    Store.singleton_class.state_accessor(:state)
    Store.state = 777
    expect(Store.state).to eq(777)
    expect(Store.instance_eval { @state }).to eq(777)
  end

  it 'state_reader class method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
    Store.singleton_class.state_reader(:state)
    Store.instance_eval { @state = 999 }
    expect(Store.state).to eq(999)
  end

  it 'state_writer class method' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
    Store.singleton_class.state_accessor(:state)
    Store.state = 777
    expect(Store.instance_eval { @state }).to eq(777)
  end
end
