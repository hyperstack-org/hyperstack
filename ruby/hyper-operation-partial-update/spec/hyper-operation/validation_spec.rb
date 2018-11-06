require 'spec_helper'

describe 'Hyperloop::Operation validations (server side)' do

  before(:each) do
    stub_const 'MyOperation', Class.new(Hyperloop::Operation)
  end

  it "will resolve the operation if the validation passes" do
    MyOperation.class_eval do
      validate { true }
    end
    expect(MyOperation.run).to be_resolved
    expect(MyOperation.run).not_to be_rejected
  end

  it "will reject the operation if the validation fails" do
    MyOperation.class_eval do
      validate { false }
    end
    expect(MyOperation.run).to be_rejected
    expect(MyOperation.run).not_to be_resolved
  end

  it "will reject the operation if the validation raises an exception" do
    MyOperation.class_eval do
      validate { fail }
    end
    expect(MyOperation.run).to be_rejected
  end

  it "will run all the validations even if some are rejected" do
    MyOperation.class_eval do
      validate { true }
      validate { false }
      validate { true }
      validate { fail }
      validate { true }
    end
    expect(MyOperation.run.error.errors.keys).to eq(['param validation 2', 'param validation 4'])
  end

  it "will not run validations after an abort!" do
    MyOperation.class_eval do
      validate { true }
      validate { false }
      validate { abort! }
      validate { MyOperation.dont_call_me  }
      validate { true }
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run.error.errors.keys).to eq(['param validation 2', 'param validation 3'])
  end

  it "will not run validations after a Hyperloop::AccessViolation error" do
    MyOperation.class_eval do
      validate { raise Hyperloop::AccessViolation }
      validate { MyOperation.dont_call_me }
    end
    expect(MyOperation).not_to receive(:dont_call_me)
    expect(MyOperation.run).to be_rejected
  end

  it "can add explicit errors using add_error in a validation" do
    MyOperation.class_eval do
      validate { add_error(:foo, :manchu, "to you!") }
    end
    result = MyOperation.run
    expect(result).to be_rejected
    errors = result.error.errors
    expect(errors.message).to eq("foo" => "to you!")
    expect(errors.symbolic).to eq("foo" => :manchu)
  end

  it "can add explicit errors using the add_error macro" do
    MyOperation.class_eval do
      add_error(:foo, :manchu, "to you!") { true }
    end
    result = MyOperation.run
    expect(result).to be_rejected
    errors = result.error.errors
    expect(errors.message).to eq("foo" => "to you!")
    expect(errors.symbolic).to eq("foo" => :manchu)
  end

  it "can skip explicit errors using the add_error macro" do
    MyOperation.class_eval do
      add_error(:foo, :manchu, "to you!") { false }
    end
    result = MyOperation.run
    expect(result).to be_resolved
  end

  it "can add explicit errors using the add_error macro after an abort" do
    MyOperation.class_eval do
      add_error(:foo, :manchu, "to you!") { abort! }
    end
    result = MyOperation.run
    expect(result).to be_rejected
    errors = result.error.errors
    expect(errors.message).to eq("foo" => "to you!")
    expect(errors.symbolic).to eq("foo" => :manchu)
  end
end

RSpec::Steps.steps 'Hyperloop::Operation validations (client side)', js: true do

  it "will resolve the operation if the validation passes" do
    expect_evaluate_ruby do
      Class.new(Hyperloop::Operation) do
        validate { true }
      end.run.resolved?
    end.to be_truthy
  end

  it "will reject the operation if the validation fails" do
    expect_evaluate_ruby do
      Class.new(Hyperloop::Operation) do
        validate { false }
      end.run.rejected?
    end.to be_truthy
  end

  it "will reject the operation if the validation raises an exception" do
    expect_evaluate_ruby do
      Class.new(Hyperloop::Operation) do
        validate { fail }
      end.run.rejected?
    end.to be_truthy
  end

  it "will run all the validations even if some are rejected" do
    expect_evaluate_ruby do
      Class.new(Hyperloop::Operation) do
        validate { true }
        validate { false }
        validate { true }
        validate { fail }
        validate { true }
      end.run.error.errors.keys
    end.to eq(['param validation 2', 'param validation 4'])
  end

  it "will not run validations after an abort!" do
    expect_evaluate_ruby do
      klass = Class.new(Hyperloop::Operation) do
        class << self
          attr_accessor :i_got_called
          def self.dont_call_me
            i_got_called = true
          end
        end
        validate { true }
        validate { false }
        validate { abort! }
        validate { MyOperation.dont_call_me  }
        validate { true }
      end
      [klass.run.error.errors.keys, klass.i_got_called]
    end.to eq [['param validation 2', 'param validation 3'], nil]
  end

  it "will not run validations after a Hyperloop::AccessViolation error" do
    expect_evaluate_ruby do
      klass = Class.new(Hyperloop::Operation) do
        class << self
          attr_accessor :i_got_called
          def self.dont_call_me
            i_got_called = true
          end
        end
        validate { raise Hyperloop::AccessViolation }
        validate { MyOperation.dont_call_me }
      end
      [klass.run.rejected?, klass.i_got_called]
    end.to eq [true, nil]
  end

  it "can add explicit errors using add_error in a validation" do
    expect_evaluate_ruby do
      result = Class.new(Hyperloop::Operation) do
        validate { add_error(:foo, :manchu, "to you!") }
      end.run
      [result.rejected?, result.error.errors.message, result.error.errors.symbolic]
    end.to eq [true, {"foo" => "to you!"}, {"foo" => 'manchu'}]
  end

  it "can add explicit errors using the add_error macro" do
    expect_evaluate_ruby do
      result = Class.new(Hyperloop::Operation) do
        add_error(:foo, :manchu, "to you!") { true }
      end.run
      [result.rejected?, result.error.errors.message, result.error.errors.symbolic]
    end.to eq [true, {"foo" => "to you!"}, {"foo" => 'manchu'}]
  end

  it "can add explicit errors using the add_error macro after an abort" do
    expect_evaluate_ruby do
      result = Class.new(Hyperloop::Operation) do
        add_error(:foo, :manchu, "to you!") { abort! }
      end.run
      [result.rejected?, result.error.errors.message, result.error.errors.symbolic]
    end.to eq [true, {"foo" => "to you!"}, {"foo" => 'manchu'}]
  end
end
