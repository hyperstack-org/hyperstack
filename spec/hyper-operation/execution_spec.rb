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
    expect(MyOperation(i: 1).value).to eq 3
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
    expect(MyOperation(i: 1).tap { MyOperation.promise.resolve(2) }.value).to eq 4
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
    expect(MyOperation(i: 1).value).to eq 'hi'
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
    expect(MyOperation(i: 1).tap { MyOperation.promise.resolve(2) }.value).to eq 2
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
    expect(MyOperation(i: 1).tap { MyOperation.promise.resolve('x') }.error.to_s).to eq 'i am a failure'
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
    expect(MyOperation().tap { MyOperation.promise.resolve('x') }.error.to_s).to eq 'I is required! Looks like i am still a failure!'
  end

  it "succeed! will skip to the end" do
    MyOperation.class_eval do
      step { succeed! "I succeeded at last!"}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me}

    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation().value).to eq 'I succeeded at last!'
  end

  it "succeed! will skip to the end and succeed even on the failure track" do
    MyOperation.class_eval do
      step { fail }
      failed { succeed! "I still can succeed!"}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me}
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation().value).to eq 'I still can succeed!'
    expect(MyOperation()).to be_resolved
  end

  it "abort! will skip to the end with a failure" do
    MyOperation.class_eval do
      step { abort! "Pride cometh before the fall!"}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me}
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation().error.result).to eq 'Pride cometh before the fall!'
  end

  it "if abort! is given an exception it will return that exception" do
    MyOperation.class_eval do
      step { abort! Exception.new("okay okay okay")}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me}
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation().error.to_s).to eq 'okay okay okay'
  end

  it "can chain an exception after returning" do
    MyOperation.class_eval do
      step { abort! Exception.new("okay okay okay")}
      step { MyOperation.dont_call_me }
      failed { MyOperation.dont_call_me}
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation().fail { |e| raise "pow" }.error.to_s).to eq 'pow'
  end

  it "can define the step, async and failed callbacks many ways" do
    stub_const 'SayHello', Class.new(Hyperloop::Operation)
    SayHello.class_eval do
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
      step   SayHello # your params will be passed along to SayHello
      async  { say_hello }
      async  :say_hello
      async  -> () { say_hello }
      async  Proc.new { say_hello }
      async  SayHello # your params will be passed along to SayHello
      step   { fail }
      failed { say_hello }
      failed :say_hello
      failed -> () { say_hello }
      failed Proc.new { say_hello }
      failed SayHello # your params will be passed along to SayHello
      failed { succeed! }
    end
    expect(MyOperation).to receive(:say_hello).exactly(15).times
    expect(MyOperation(xxx: 123)).to be_resolved
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
