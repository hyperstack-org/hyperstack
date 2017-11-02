require 'spec_helper'

describe 'Hyperloop::Operation execution (server side)' do

  before(:each) do
    stub_const 'MyOperation', Class.new(Hyperloop::Operation)
  end

  it "will execute some steps" do
    MyOperation.class_eval do
      param :i
      step { params.i + 1 }
      step { |r| r + params.i }
    end
    expect(MyOperation.run(i: 1).value).to eq 3
  end

  it "will chain promises" do
    MyOperation.class_eval do
      def self.promise
        @promise ||= Promise.new
      end
      param :i
      step { self.class.promise }
      step { |n| params.i + n }
      step { |r| r + params.i }
    end
    expect(MyOperation.run(i: 1).tap { MyOperation.promise.resolve(2) }.value).to eq 4
  end

  it "will interrupt the promise chain with async" do
    MyOperation.class_eval do
      def self.promise
        @promise ||= Promise.new
      end
      param :i
      step { self.class.promise }
      step { |n| params.i + n }
      step { |r| r + params.i }
      async { 'hi' }
    end
    expect(MyOperation.run(i: 1).value).to eq 'hi'
  end

  it "will continue running after the async" do
    MyOperation.class_eval do
      def self.promise
        @promise ||= Promise.new
      end
      param :i
      step { self.class.promise }
      step { |n| params.i + n }
      step { |r| r + params.i }
      async { 'hi' }
      step { self.class.promise }
    end
    expect(MyOperation.run(i: 1).tap { MyOperation.promise.resolve(2) }.value).to eq 2
  end

  it "will switch to the failure track on an error" do
    MyOperation.class_eval do
      def self.promise
        @promise ||= Promise.new
      end
      param :i
      step { self.class.promise }
      step { |n| params.i + n }
      failed { raise 'i am a' }
      step { MyOperation.dont_call_me }
      failed { |s| raise "#{s} failure" }
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run(i: 1).tap { MyOperation.promise.resolve('x') }.error.to_s).to eq 'i am a failure'
  end

  it "will begin on the failure track if there are validation errors" do
    MyOperation.class_eval do
      def self.promise
        @promise ||= Promise.new
      end
      param :i
      step { MyOperation.dont_call_me }
      step { |n| params.i + n }
      failed { |s| raise "#{s}! Looks like i am still a" }
      step { MyOperation.dont_call_me }
      failed { |s| "#{s} failure!" }
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run.tap { MyOperation.promise.resolve('x') }.error.to_s).to eq 'I is required! Looks like i am still a failure!'
  end

  it "succeed! will skip to the end" do
    MyOperation.class_eval do
      step { succeed! "I succeeded at last!"}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me }

    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run.value).to eq 'I succeeded at last!'
  end

  it "succeed! will skip to the end and succeed even on the failure track" do
    MyOperation.class_eval do
      step { fail }
      failed { succeed! "I still can succeed!"}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me }
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run.value).to eq 'I still can succeed!'
    expect(MyOperation.run).to be_resolved
  end

  it "abort! will skip to the end with a failure" do
    MyOperation.class_eval do
      step { abort! "Pride cometh before the fall!"}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me}
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run.error.result).to eq 'Pride cometh before the fall!'
  end

  it "if abort! is given an exception it will return that exception" do
    MyOperation.class_eval do
      step { abort! Exception.new("okay okay okay")}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me }
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run.error.to_s).to eq 'okay okay okay'
  end

  it "can chain an exception after returning" do
    MyOperation.class_eval do
      step { abort! Exception.new("okay okay okay")}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me }
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run.fail { |e| raise "pow" }.error.to_s).to eq 'pow'
  end

  it "can define the step, async and failed callbacks many ways" do
    stub_const 'SayHelloOp', Class.new(Hyperloop::Operation)
    SayHelloOp.class_eval do
      param :xxx
      step { MyOperation.say_hello if params.xxx == 123 }
    end
    MyOperation.class_eval do
      param :xxx
      def say_hello()
        MyOperation.say_hello
      end
      step   { say_hello }
      step   :say_hello
      step   -> () { say_hello }
      step   proc { say_hello }
      step   SayHelloOp # your params will be passed along to SayHelloOp
      async  { say_hello }
      async  :say_hello
      async  -> () { say_hello }
      async  Proc.new { say_hello }
      async  SayHelloOp # your params will be passed along to SayHelloOp
      step   { fail }
      failed { say_hello }
      failed :say_hello
      failed -> () { say_hello }
      failed Proc.new { say_hello }
      failed SayHelloOp # your params will be passed along to SayHelloOp
      failed { succeed! }
    end
    expect(MyOperation).to receive(:say_hello).exactly(15).times
    expect(MyOperation.run(xxx: 123)).to be_resolved
  end

  it "can define class level callbacks" do
    MyOperation.class_eval do
      step(:class) { say_hello }
      step   class: :say_hello
      step   class: -> () { say_hello }
      step   class: proc { say_hello }
      async(:class) { say_hello }
      async  class: :say_hello
      async  class: -> () { say_hello }
      async  class: Proc.new { say_hello }
      step   { fail }
      failed(:class) { say_hello }
      failed class: :say_hello
      failed class: -> () { say_hello }
      failed class: Proc.new { say_hello }
      failed { succeed! }
    end
    expect(MyOperation).to receive(:say_hello).exactly(12).times
    expect(MyOperation.run).to be_resolved
  end

  it 'can provide options different ways' do
    MyOperation.class_eval do
      def say_instance_hello()
        MyOperation.say_hello
      end
      step(scope: :class) { say_hello }
      step scope: :class, run: proc { say_hello }
      step run: :say_instance_hello
      step :say_hello, scope: :class
    end
    expect(MyOperation).to receive(:say_hello).exactly(4).times
    expect(MyOperation.run).to be_resolved
  end
end

RSpec::Steps.steps 'Hyperloop::Operation execution (client side)', js: true do

  before(:step) do
    on_client do
      def get_round_tuit(value)
        Promise.new.tap { |p| after(0.1) { p.resolve(value) } }
      end
      module DontCallMe
        def called?
          @called
        end
        def dont_call_me
          @called = true
        end
      end
      module HelloCounter
        def hello_count
          @called || 0
        end
        def say_hello
          @called ||= 0
          @called += 1
        end
      end
    end
  end

  it "will execute some steps" do
    expect_evaluate_ruby do
      Class.new(Hyperloop::Operation) do
        param :i
        step { params.i + 1 }
        step { |r| r + params.i }
      end.run(i: 1).value
    end.to eq 3
  end

  it "will chain promises" do
    expect_promise do
      Class.new(Hyperloop::Operation) do
        param :i
        step { get_round_tuit(2) }
        step { |n| params.i + n }
        step { |r| r + params.i }
      end.run(i: 1)
    end.to eq 4
  end

  it "will interrupt the promise chain with async" do
    expect_promise do
      Class.new(Hyperloop::Operation) do
        param :i
        step { get_round_tuit(2) }
        step { |n| params.i + n }
        step { |r| r + params.i }
        async { 'hi' }
      end.run(i: 1)
    end.to eq 'hi'
  end

  it "will continue running after the async" do
    expect_promise do
      Class.new(Hyperloop::Operation) do
        param :i
        step { get_round_tuit(2) }
        step { |n| params.i + n }
        step { |r| r + params.i }
        async { 'hi' }
        step { get_round_tuit(2) }
      end.run(i: 1)
    end.to eq 2
  end

  it "will switch to the failure track on an error" do
    expect_promise do
      operation = Class.new(Hyperloop::Operation) do
        extend DontCallMe
        param :i
        step { get_round_tuit('x') }
        step { |n| params.i + n }
        failed { raise 'i am a' }
        step { self.class.dont_call_me }
        failed { |s| raise "#{s.message} failure" }
      end
      operation.run(i: 1).always { |e| e.message unless operation.called? }
    end.to eq 'i am a failure'
  end

  it "will begin on the failure track if there are validation errors" do
    expect_promise do
      operation = Class.new(Hyperloop::Operation) do
        extend DontCallMe
        param :i
        step   { self.class.dont_call_me }
        step   { |n| params.i + n }
        failed { |s| raise "#{s.message}! Looks like i am still a" }
        step   { self.class.dont_call_me }
        failed { |s| "#{s.message} failure!" }
      end
      operation.run.always { |e| e unless operation.called? }
    end.to eq 'i is required! Looks like i am still a failure!'
  end

  it "succeed! will skip to the end" do
    expect_promise do
      operation = Class.new(Hyperloop::Operation) do
        extend DontCallMe
        step { succeed! "I succeeded at last!"}
        step { MyOperation.dont_call_me }
        failed { MyOperation.dont_call_me}
      end
      operation.run.then { |e| e unless operation.called? }
    end.to eq 'I succeeded at last!'
  end

  it "succeed! will skip to the end and succeed even on the failure track" do
    expect_evaluate_ruby do
      operation = Class.new(Hyperloop::Operation) do
        extend DontCallMe
        step { fail }
        failed { succeed! "I still can succeed!"}
        step { self.class.dont_call_me }
        failed { self.class.dont_call_me }
      end
      result = operation.run
      [operation.called?, result.value, result.resolved?]
    end.to eq [nil, 'I still can succeed!', true]
  end

  it "abort! will skip to the end with a failure" do
    expect_evaluate_ruby do
      operation = Class.new(Hyperloop::Operation) do
        extend DontCallMe
        step { abort! "Pride cometh before the fall!"}
        step { self.class.dont_call_me }
        failed { self.class.dont_call_me}
      end
      result = operation.run
      [operation.called?, result.rejected?, result.error.result]
    end.to eq [nil, true, 'Pride cometh before the fall!']
  end

  it "if abort! is given an exception it will return that exception" do
    expect_evaluate_ruby do
      operation = Class.new(Hyperloop::Operation) do
        extend DontCallMe
        step { abort! Exception.new("okay okay okay")}
        step { MyOperation.dont_call_me }
        failed { MyOperation.dont_call_me}
      end
      result = operation.run
      [operation.called?, result.rejected?, result.error.message]
    end.to eq [nil, true, 'okay okay okay']
  end


  it "can define the step, async and failed callbacks many ways" do
    expect_evaluate_ruby do

      operation = Class.new(Hyperloop::Operation)

      class SayHelloOp < Hyperloop::Operation
        param :xxx
        step { operation.say_hello if params.xxx == 123 }
      end

      operation.class_eval do
        param :xxx
        extend HelloCounter
        def say_hello()
          self.class.say_hello
        end
        step   { say_hello }
        step   :say_hello
        step   -> () { say_hello }
        step   proc { say_hello }
        step   SayHelloOp # your params will be passed along to SayHelloOp
        async  { say_hello }
        async  :say_hello
        async  -> () { say_hello }
        async  Proc.new { say_hello }
        async  SayHelloOp # your params will be passed along to SayHelloOp
        step   { fail }
        failed { say_hello }
        failed :say_hello
        failed -> () { say_hello }
        failed Proc.new { say_hello }
        failed SayHelloOp # your params will be passed along to SayHelloOp
        failed { succeed! }
      end
      result = operation.run(xxx: 123)
      [operation.hello_count, result.resolved?]
    end.to eq [15, true]
  end

  it "can define class level callbacks" do
    expect_evaluate_ruby do
      operation = Class.new(Hyperloop::Operation) do
        extend HelloCounter
        step(:class) { say_hello }
        step   class: :say_hello
        step   class: -> () { say_hello }
        step   class: proc { say_hello }
        async(:class) { say_hello }
        async  class: :say_hello
        async  class: -> () { say_hello }
        async  class: Proc.new { say_hello }
        step   { fail }
        failed(:class) { say_hello }
        failed class: :say_hello
        failed class: -> () { say_hello }
        failed class: Proc.new { say_hello }
        failed { succeed! }
      end
      [operation.run.resolved?, operation.hello_count]
    end.to eq [true, 12]
  end

  it 'can provide options different ways' do
    expect_evaluate_ruby do
      operation = Class.new(Hyperloop::Operation) do
        extend HelloCounter
        def say_instance_hello()
          self.class.say_hello
        end
        step(scope: :class) { say_hello }
        step scope: :class, run: proc { say_hello }
        step run: :say_instance_hello
        step :say_hello, scope: :class
      end
      [operation.run.resolved?, operation.hello_count]
    end.to eq [true, 4]
  end
end
