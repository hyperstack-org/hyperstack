require 'spec_helper'

# Just checks to make sure all methods are available when either subclassing or including
describe Hyperstack::State do
  before(:each) do
  end

  context 'public state api' do

    context 'state object caching and inheritance' do
      class Store
        include Hyperstack::State
        state :instance_s
        state :instance_y
        state :class_s, scope: :class
        state :class_y, scope: :class
      end
      class ChildStore < Store
        state :instance_s
        state :class_s, scope: :class
      end
      let(:store1) { Store.new }
      let(:store2) { Store.new }
      it "caches instance state objects" do
        expect(store1.instance_s).to be(store1.instance_s)
      end
      it "does not share instance state objects across instances" do
        expect(store1.instance_s).not_to be(store2.instance_s)
      end
      it "caches class state objects" do
        expect(Store.class_s).to be(Store.class_s)
      end
      it "the cache is inherited" do
        expect(Store.class_y).to be(ChildStore.class_y)
      end
      it "class state methods can be overridden in child classes" do
        expect(Store.class_s).not_to be(ChildStore.class_s)
      end
    end

    context 'initializing, reading, updating, and mutating an instance state' do

      before(:each) do
        class Store
          include Hyperstack::State
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
          unless method == :to_nil
            expect(Hyperstack::Internal::State).to receive(:set_state).with(store, method, expected_value)
          end
          expect(Hyperstack::Internal::State).to receive(:get_state).with(store, method).and_return(expected_value)
          expect(store.send(method).state).to be expected_value # states are initialized on first read
        end
      end
      it "can set a state using the assignment operator" do
        store = Store.new
        expect(Hyperstack::Internal::State).to receive(:set_state).with(store, :to_nil, "Not Nil Anymore").and_call_original
        expect(Hyperstack::Internal::State).to receive(:get_state).with(store, :to_nil).and_return("Not Nil Anymore")
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
        expect(Hyperstack::Internal::State).to receive(:set_state).with(store, :to_nil, a_hash).and_call_original
        store.to_nil.state = a_hash
        expect(Hyperstack::Internal::State).to receive(:set_state).with(store, :to_nil, a_hash).and_call_original
        store.to_nil.mutate[:key] = :value
        expect(a_hash).to eq(key: :value)
      end

    end
  end
end
