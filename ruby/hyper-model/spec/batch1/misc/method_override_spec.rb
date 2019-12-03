require 'spec_helper'
require 'test_components'
require 'rspec-steps'

RSpec::Steps.steps  "overriding attribute methods", js: true do

  before(:all) do
    TypeTest.build_tables
  end

  it 'can override the getter' do
    expect_evaluate_ruby do
      TypeTest.class_eval do
        def string
          super.reverse
        end
      end
      TypeTest.new(string: 'hello').string
    end.to eq('hello'.reverse)
  end

  it 'can override the forced getter' do
    expect_evaluate_ruby do
      TypeTest.class_eval do
        def string!
          !super
        end
      end
      TypeTest.new(string: 'hello').string!
    end.to eq(true)
  end

  it 'can override the setter' do
    expect_evaluate_ruby do
      TypeTest.class_eval do
        def integer=(x)
          super(-x)
        end
      end
      test = TypeTest.new
      test.integer = 12
      test.integer
    end.to eq(-12)
  end

  it 'can override the _changed method' do
    expect_evaluate_ruby do
      TypeTest.class_eval do
        def integer_changed?
          integer.even? ? super : false
        end
      end
      [TypeTest.new(integer: 6).integer_changed?, TypeTest.new(integer: 7).integer_changed?]
    end.to eq([true, false])
  end

  it 'can override the boolean ? method' do
    expect_evaluate_ruby do
      TypeTest.class_eval do
        def boolean?
          !super
        end
      end
      TypeTest.new(boolean: true).boolean?
    end.to eq(false)
  end

end
