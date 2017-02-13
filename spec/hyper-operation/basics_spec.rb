require 'spec_helper'

describe 'HyperOperation basics' do

  it "HyperOperation is defined" do
    expect(HyperOperation).to be_a_kind_of(Class)
  end

  it "can be run and will dispatch to each receiver" do
    stub_const 'MyOperation', Class.new(HyperOperation)
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
    stub_const 'MyOperation', Class.new(HyperOperation)
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
      stub_const 'MyOperation', Class.new(HyperOperation)
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
      .to have_failed_with(HyperOperation::ValidationException)
    end

    it "will fail if a required param is missing" do
      MyOperation.param :foo, type: Integer
      expect(Store).not_to receive(:receiver)
      expect(MyOperation.run)
      .to have_failed_with(HyperOperation::ValidationException)
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
      MyOperation.run(foo: 15, bar: 'hello')
    end

    it "checks parameter types" do
      MyOperation.param :sku, type: String
      MyOperation.param qty: 1, type: Integer, min: 1
      expect(Store).to receive(:receiver).with({sku: "i'm skewed alright", qty: 1})
      expect(MyOperation.run(sku: "i'm skewed alright")).to be_resolved
      expect(MyOperation.run(sku: "i'm skewed alright", qty: 3.2))
      .to have_failed_with(HyperOperation::ValidationException)
      expect(MyOperation.run(qty: 3))
      .to have_failed_with(HyperOperation::ValidationException)
      expect(MyOperation.run(sku: "i'm skewed alright", qty: 0))
      .to have_failed_with(HyperOperation::ValidationException)
    end

    it "can have an execute method" do
      MyOperation.param :sku, type: String
      MyOperation.send(:define_method, :execute) do
        dispatch sku: 'fred'
      end
      expect(Store).to receive(:receiver).with({sku: 'fred'})
      expect(MyOperation.run(sku: 'anything but fred')).to be_resolved
    end

    it "can have outbound params" do
      MyOperation.param :sku, type: String
      MyOperation.param qty: 1, type: Integer, min: 1
      MyOperation.outbound :available
      MyOperation.send(:define_method, :execute) do
        params.available = params.qty - 1
        dispatch qty: 100
      end
      expect(Store).to receive(:receiver).with({sku: "sku", qty: 100, available: 3})
      expect(MyOperation.run(sku: "sku", qty: 4)).to be_resolved
    end

    it "dispatch will not accept undeclared parameters" do
      MyOperation.param :sku, type: String
      MyOperation.param qty: 1, type: Integer, min: 1
      MyOperation.send(:define_method, :execute) do
        dispatch qtyz: 100
      end
      expect(Store).not_to receive(:receiver)
      expect(MyOperation.run(sku: "sku", qty: 4)).to have_failed_with(NoMethodError)
    end

    it "params cannot be updated in a reciever" do
      MyOperation.param :sku, type: String
      Store.class_eval do
        MyOperation.on_dispatch { |params| params.sku = nil }
      end
      expect(MyOperation.run(sku: "sku")).to have_failed_with(NoMethodError)
    end

    it "can have a class execute method" do
      MyOperation.outbound :count
      MyOperation.class_eval do
        class << self
          def count
            @count ||= 0
            @count += 1
          end
          def execute
            dispatch count: count
          end
        end
      end
      expect(Store).to receive(:receiver).with({count: 1})
      expect(Store).to receive(:receiver).with({count: 2})
      expect(MyOperation.then { MyOperation.run }).to be_resolved
    end

    it "can be run with the run method", js: true do
      stub_const "Foo", Class.new
      stub_const "Mod", Module.new
      stub_const "Klass", Class.new
      isomorphic do
        class Foo
          def call_it
            Mod::Op2()
          end
          def self.call_it
            Mod::Op2()
          end
        end
        module Mod
          class Op < HyperOperation
            def execute
              Op2().then { |s1| Mod::Op2().then { |s2| s1+s2 } }
            end
          end
          class Op2 < HyperOperation
            def execute
              "Op2()"
            end
          end
        end
        class Klass
          class Op < HyperOperation
            def execute
              Op2().then { |s1| Klass::Op2().then { |s2| s1+s2 } }
            end
          end
          class Op2 < HyperOperation
            def execute
              "COp2()"
            end
          end
        end
      end
      expect_promise(Mod::Op()).to eq("Op2()Op2()")
      expect_promise(Foo.new.call_it).to eq("Op2()")
      expect_promise(Foo.call_it).to eq("Op2()")
      expect_promise(Klass::Op()).to eq("COp2()COp2()")
      expect_promise do
        Mod::Op()
      end.to eq("Op2()Op2()")
      expect_promise do
        Foo.new.call_it
      end.to eq("Op2()")
      expect_promise do
        Foo.call_it
      end.to eq("Op2()")
      expect_promise do
        Klass::Op()
      end.to eq("COp2()COp2()")
    end

  end

  it "will use the promise returned by execute", js: true do
    isomorphic do
      class MyOperation < HyperOperation
        param :wait, type: Float, min: 0
        param :result
        def execute
          Promise.new.tap { |p| after(params.wait) { p.resolve params.result } }
        end
      end
    end
    start_time = Time.now
    expect_promise do
      MyOperation.run(wait: 1, result: 'done')
    end.to eq('done')
    expect(Time.now - start_time).to be >= 1
    expect_promise(MyOperation.run(wait: 1, result: 'done')).to eq('done')
    expect(Time.now - start_time).to be >= 2
  end

  it "can combine the operations with a Promise.when", js: true do
    on_client do
      class SomeOperation < HyperOperation
        param :wait
        def execute
          Promise.new.tap { |p| after(params.wait) { p.resolve } }
        end
      end
      class DoABunchOStuff < HyperOperation
        def execute
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
        Hyperloop::Boot.on_dispatch do
          @bootcount ||= 0
          @bootcount += 1
        end
      end
    end
    expect_evaluate_ruby("Receiver.bootcount").to eq(1)
    evaluate_ruby("Hyperloop.Boot()")
    expect_evaluate_ruby("Receiver.bootcount").to eq(2)
  end
end
