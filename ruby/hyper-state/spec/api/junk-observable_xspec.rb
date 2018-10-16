require 'spec_helper'

# Just checks to make sure all methods are available when either subclassing or including

describe Hyperstack::State::Observable do
  context 'state object methods and inheritance' do
    class Store
      include Hyperstack::State::Observable
      state :instance_s
      state :instance_y
      state :class_s, scope: :class
      state :class_y, scope: :class
      state :shared, scope: :shared
      class << self
        state :singleton_klass, scope: :class
        state :singleton_instance, scope: :instance
        state :singleton_shared, scope: :shared
      end
    end
    class ChildStore < Store
      state :instance_s
      state :class_s, scope: :class
    end
    let(:store1) { Store.new }
    let(:store2) { Store.new }
    it "instance state objects hold state" do
      store1.instance_s.state = :foo
      expect(store1.instance_s.state).to eq(:foo)
    end
    it "does not share instance state objects across instances" do
      expect(store1.instance_s).not_to be(store2.instance_s)
    end
    it "class state objects hold state" do
      Store.class_s.state = :foo
      expect(Store.class_s.state).to eq(:foo)
    end
    it "the state method can be inherited" do
      expect(Store.class_y).to be(ChildStore.class_y)
    end
    it "class state methods can be overridden in child classes" do
      expect(Store.class_s).not_to be(ChildStore.class_s)
    end
    it "defines a shared method in both class and state" do
      expect(Store.shared).to be(store1.shared)
    end
    it "defines a class method from within the singleton class" do
      Store.singleton_klass.state = :singleton_klass
      expect(Store.singleton_klass.state).to eq(:singleton_klass)
    end
    it "defines an instance method from within the singleton class" do
      store1.singleton_instance.state = :singleton_instance
      expect(Store.singleton_instance.state).to eq(:singleton_instance)
    end
    it "defines a shared method from within the singleton class" do
      expect(Store.singleton_shared).to be(store1.singleton_shared)
    end
  end

  context 'initializing, reading, updating, and mutating an instance state' do

    before(:each) do
      class Store
        include Hyperstack::State::Observable
        def initialize(init_value = nil)
          @init_value = init_value
        end
        def get_initial_value
          @init_value
        end
        state :to_nil
        state with_hash_value: :hash_value
        state :with_initializer_symbol, initializer: :get_initial_value
        state :with_initializer_string, initializer: "get_initial_value"
        state :with_initializer_proc, initializer: -> () { @init_value }
        state :with_a_block do
          @init_value
        end
      end
    end
    [
      ['to nil', :to_nil, nil],
      ['with a name => value pair', :with_hash_value, :hash_value],
      ['using the initialize option and a method name', :with_initializer_symbol, :init_sym_name],
      ['using the initialize option and a method string name', :with_initializer_string, :init_string_name],
      ['using the initialize option and a proc', :with_initializer_proc, :init_with_proc],
      ['with a block', :with_a_block, :block_value]
    ].each do |name, method, expected_value|
      it "state can be initialized #{name}" do
        store = Store.new(expected_value)
        sent_to_mutated = nil
        original_mutated = Hyperstack::Internal::State::Mapper.method(:mutated!)
        unless method == :to_nil
          allow(Hyperstack::Internal::State::Mapper).to receive(:mutated!) do |obj|
            sent_to_mutated = obj
            original_mutated.call obj
          end
          expect(store.send(method)).to eq(sent_to_mutated)
        end
        expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store.send(method))
        expect(store.send(method).state).to eq(expected_value)
      end
    end
    it "can set a state using the assignment operator" do
      store = Store.new
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store.to_nil).and_call_original
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store.to_nil).and_call_original
      store.to_nil.state = "Not Nil Anymore"
      expect(store.to_nil.state).to eq("Not Nil Anymore")
    end
    it "can reverse a state's polarity using the toggle! method" do
      store = Store.new
      store.to_nil.toggle!
      expect(store.to_nil.state).to be true
    end
    it "can read the state as a boolean using set?" do
      store = Store.new
      expect(store.to_nil.set?).to be false
    end
    it "can read the state as a boolean using clear?" do
      store = Store.new
      expect(store.to_nil.clear?).to be true
    end
    it "can read the state as a boolean using nil?" do
      store = Store.new
      expect(store.to_nil.nil?).to be true
    end
    it "can observe the mutation of a state's value" do
      store = Store.new
      a_hash = {}
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).twice.with(store.to_nil).and_call_original
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).once.with(store.to_nil).and_call_original

      store.to_nil.state = a_hash
      store.to_nil.mutate[:key] = :value
      expect(a_hash).to eq(key: :value)
    end
    it "can observe a block of mutations" do
      store = Store.new
      a_hash = {}
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).twice.with(store.to_nil).and_call_original
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).once.with(store.to_nil).and_call_original

      store.to_nil.state = a_hash
      store.to_nil.mutate do
        store.to_nil.state[:key] = :value
      end
      expect(a_hash).to eq(key: :value)
    end
    it "can observe a block of mutations passing the state" do
      store = Store.new
      a_hash = {}
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).twice.with(store.to_nil).and_call_original
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).once.with(store.to_nil).and_call_original
      store.to_nil.state = a_hash
      store.to_nil.mutate do |hash|
        hash[:key] = :value
      end
      expect(a_hash).to eq(key: :value)
    end
    context "observe and mutate class and instance methods" do
      it "will add the observe and mutate method to the instances" do
        store = Store.new
        expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).once.with(store).and_call_original
        expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).once.with(store).and_call_original

        expect(store.instance_eval { mutate { @secret_val = 12 } }).to eq(12)
        expect(store.instance_eval { @secret_val }).to eq(12)
        expect(store.instance_eval { observe { @secret_val } }).to eq(12)
      end
      it "will add the observe and mutate method to the class" do
        expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).once.with(Store).and_call_original
        expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).once.with(Store).and_call_original

        expect(Store.instance_eval { mutate { @secret_val = 12 } }).to eq(12)
        expect(Store.instance_eval { @secret_val }).to eq(12)
        expect(Store.instance_eval { observe { @secret_val } }).to eq(12)
      end
    end
  end
end
