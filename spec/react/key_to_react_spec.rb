require 'spec_helper'

describe 'key_to_react helper', js: true do
  it "will use the use the to_key method to get the react key" do
    mount "TestComponent" do
      class MyTestClass
        attr_reader :to_key_called
        def to_key
          @to_key_called = true
          super
        end
      end
      class TestComponent < Hyperloop::Component
        before_mount { @test_object = MyTestClass.new }
        render do
          DIV(key: @test_object) { TestComponent2(test_object: @test_object) }
        end
      end
      class TestComponent2 < Hyperloop::Component
        param :test_object
        render do
          "to key was called!" if params.test_object.to_key_called
        end
      end
    end
    pause
    expect(page).to have_content('to key was called!')
  end
end
