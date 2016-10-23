require 'spec_helper'

describe 'component helpers', js: true do

  it "can mount" do

    mount "MyComponent" do
      class MyComponent < React::Component::Base
        class << self
          attr_accessor :foo
        end
        after_mount do
          self.class.foo = 12
        end
        render do
          "hello"
        end
      end
    end
    page.evaluate_ruby("MyComponent.foo").should eq(12)
    page.evaluate_ruby("TestModel").should eq("TestModel")
  end

  it "can instrument some methods" do
    mount "MyComponent" do
      class MyComponent < React::Component::Base
        def some_method
          "fact(5) = #{SomeClass.new.fact(5)}"
        end
        def render
          some_method
        end
      end
      class SomeClass
        def fact(n)
          n == 1 ? n : fact(n-1) * n
        end
      end
      SomeClass.hyper_trace do
        instrument :all
        break_on_exit?(:fact) { |r, n| puts "self = #{self}"; n == 1 }
      end
      MyComponent.hyper_trace instrument: :all, break_on_exit: [:some_method, :render]
    end
    pause
  end
end
