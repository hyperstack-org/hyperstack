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
end
