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
end
