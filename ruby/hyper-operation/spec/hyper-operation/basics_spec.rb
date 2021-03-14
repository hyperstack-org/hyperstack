require 'spec_helper'

describe 'Hyperstack::Operation basics' do

  it "Hyperstack::Operation is defined" do
    expect(Hyperstack::Operation).to be_a_kind_of(Class)
  end

  it "can be run and will dispatch to each receiver" do
    stub_const 'MyOperation', Class.new(Hyperstack::Operation)
    stub_const 'BaseStore', Class.new
    BaseStore.class_eval do
      def self.inherited(child)
        MyOperation.on_dispatch { child.receiver }
      end
    end
    2.times { Class.new(BaseStore) }
    expect(BaseStore).to receive(:receiver).with(no_args).twice
    MyOperation.run
  end

  it "can be subclassed" do
    stub_const 'MyOperation', Class.new(Hyperstack::Operation)
    stub_const 'MySubOperation', Class.new(MyOperation)
    stub_const 'BaseStore', Class.new
    BaseStore.class_eval do
      MySubOperation.on_dispatch { sub_receiver }
      MyOperation.on_dispatch { receiver }
    end
    expect(BaseStore).to receive(:receiver).with(no_args).once
    expect(BaseStore).to receive(:sub_receiver).with(no_args).once
    MyOperation.run
    MySubOperation.run
  end

  context "parameters" do
    before(:each) do
      stub_const 'MyOperation', Class.new(Hyperstack::Operation)
      stub_const 'Store', Class.new
      Store.class_eval do
        MyOperation.on_dispatch { |params| receiver(params.to_h) }
      end
    end

    it "will be passed to the recievers" do
      expect(Store).to receive(:receiver).with({})
      result = MyOperation.run
      expect(result).to be_resolved
    end

    it "can pass a parameter to the receiver" do
      MyOperation.param :foo
      expect(Store).to receive(:receiver).with({foo: 12})
      result = MyOperation.run(foo: 12)
      expect(result).to be_resolved
    end

    it "can have a type" do
      MyOperation.param :foo, type: Integer
      expect(Store).to receive(:receiver).with({foo: 12})
      result = MyOperation.run(foo: 12)
      expect(result).to be_resolved
    end

    it "will fail if the wrong type is passed" do
      MyOperation.param :foo, type: Integer
      expect(Store).not_to receive(:receiver)
      expect(MyOperation.run(foo: "hello"))
      .to have_failed_with(Hyperstack::Operation::ValidationException)
    end

    it "will fail if a required param is missing" do
      MyOperation.param :foo, type: Integer
      expect(Store).not_to receive(:receiver)
      expect(MyOperation.run)
      .to have_failed_with(Hyperstack::Operation::ValidationException)
    end

    it "can have a default parameter" do
      MyOperation.param foo: 12, type: Integer
      expect(Store).to receive(:receiver).with({foo: 12})
      result = MyOperation.run
      expect(result).to be_resolved
    end

    it "param declarations will be passed to subclasses" do
      MyOperation.param foo: 12, type: Integer
      stub_const "SubOperation", Class.new(MyOperation)
      SubOperation.param :bar
      expect(Store).to receive(:receiver).with(foo: 15, bar: 'hello')
      SubOperation.run(foo: 15, bar: 'hello')
    end

    it "checks parameter types" do
      MyOperation.param :sku, type: String
      MyOperation.param qty: 1, type: Integer, min: 1
      expect(Store).to receive(:receiver).with({sku: "i'm skewed alright", qty: 1})
      expect(MyOperation.run(sku: "i'm skewed alright")).to be_resolved
      expect(MyOperation.run(sku: "i'm skewed alright", qty: 3.2))
      .to have_failed_with(Hyperstack::Operation::ValidationException)
      expect(MyOperation.run(qty: 3))
      .to have_failed_with(Hyperstack::Operation::ValidationException)
      expect(MyOperation.run(sku: "i'm skewed alright", qty: 0))
      .to have_failed_with(Hyperstack::Operation::ValidationException)
    end

    it "can have array, array of types, or hash types" do
      MyOperation.param :array, type: []
      MyOperation.param :int_array, type: [Integer]
      MyOperation.param :hash, type: {}
      expect(Store).to receive(:receiver).with(array: ['hi'], int_array: [1], hash: {a: 1})
      expect(MyOperation.run(array: ['hi'], int_array: [1], hash: {a: 1})).to be_resolved
      expect(MyOperation.run(array: 'hi', int_array: [1], hash: {a: 1}))
      .to have_failed_with(Hyperstack::Operation::ValidationException)
      expect(MyOperation.run(array: ['hi'], int_array: ['hi'], hash: {a: 1}))
      .to have_failed_with(Hyperstack::Operation::ValidationException)
      expect(MyOperation.run(array: ['hi'], int_array: [1], hash: nil))
      .to have_failed_with(Hyperstack::Operation::ValidationException)
    end

    it "can use complex Mutations filters" do
      MyOperation.param :hash, type: Hash do
        string :a
        integer :b
      end
      expect(Store).to receive(:receiver).with(hash: {a: '1', b: 1})
      expect(MyOperation.run(hash: {a: '1', b: '1'})).to be_resolved
    end

    it "has a step method" do
      MyOperation.param :sku, type: String
      MyOperation.step { params.sku = 'fred' }
      expect(Store).to receive(:receiver).with({sku: 'fred'})
      expect(MyOperation.run(sku: 'anything but fred')).to be_resolved
    end

    it "can have outbound params" do
      MyOperation.param :sku, type: String
      MyOperation.param qty: 1, type: Integer, min: 1
      MyOperation.outbound :available
      MyOperation.step { params.available = params.qty - 1 }
      MyOperation.step { params.qty = 100 }
      expect(Store).to receive(:receiver).with({sku: "sku", qty: 100, available: 3})
      expect(MyOperation.run(sku: "sku", qty: 4)).to be_resolved
    end

    it "can have inbound params" do
      MyOperation.inbound :inbounder
      MyOperation.outbound :outbounder
      MyOperation.step { params.outbounder = params.inbounder }
      expect(Store).to receive(:receiver).with({outbounder: 'hello'})
      expect(MyOperation.run(inbounder: 'hello')).to be_resolved
    end

    it "params cannot be updated in a reciever" do
      MyOperation.param :sku, type: String
      Store.class_eval do
        def self.receiver(*args)
        end
        MyOperation.on_dispatch do |params|
          begin
            params.sku = nil
          rescue Exception => e
            error(e)
          end
        end
      end
      expect(Store).to receive(:error).with(NameError)
      MyOperation.run(sku: "sku")
    end

    it "can have a class step method" do
      MyOperation.outbound :count
      MyOperation.class_eval do
        class << self
          def count
            @count ||= 0
            @count += 1
          end
          step { |op| op.params.count = count }
        end
      end
      expect(Store).to receive(:receiver).with({count: 1})
      expect(Store).to receive(:receiver).with({count: 2})
      expect(MyOperation.then { MyOperation.run }).to be_resolved
    end
  end

  it "will use the promise returned by execute", js: true do
    isomorphic do
      class MyOperation < Hyperstack::Operation
        include Hyperstack::AsyncSleep
        param :wait, type: Float, min: 0
        param :result
        step do
          pro = Promise.new.tap { |p| after(params.wait) { p.resolve params.result } }
          pro
        end
      end
    end
    start_time = Time.now
    expect_promise do
      MyOperation.run(wait: 1.0, result: 'done')
    end.to eq('done')
    expect(Time.now - start_time).to be >= 1
    expect_promise(MyOperation.run(wait: 1.0, result: 'done')).to eq('done')
    expect(Time.now - start_time).to be >= 2
  end

  it "can combine the operations with a Promise.when", js: true do
    on_client do
      class SomeOperation < Hyperstack::Operation
        param :wait
        step do
          Promise.new.tap { |p| after(params.wait) { p.resolve } }
        end
      end
      class DoABunchOStuff < Hyperstack::Operation
        step do
          start_time = Time.now
          Promise.when(SomeOperation.run(wait: 2), SomeOperation.run(wait: 1)).then do
            Time.now - start_time
          end
        end
      end
    end
    expect_promise do
      DoABunchOStuff.run
    end.to be >= 2
  end

  it "tells us when things boot", js: true do
    on_client do
      class Receiver
        def self.bootcount
          @bootcount ||= 0
        end
        Hyperstack::Application::Boot.on_dispatch do
          @bootcount ||= 0
          @bootcount += 1
        end
      end
    end
    expect_evaluate_ruby("Receiver.bootcount").to eq(1)
    evaluate_ruby("Hyperstack::Application::Boot.run")
    expect_evaluate_ruby("Receiver.bootcount").to eq(2)
  end
end
