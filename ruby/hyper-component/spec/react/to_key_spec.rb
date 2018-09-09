require 'spec_helper'

describe 'to_key helper', js: true do
  it "has added 'to_key' method to Object and each key is different" do
    expect_evaluate_ruby do
      Object.new.to_key != Object.new.to_key
    end.to be_truthy
  end

  it "to_key return 'self' for String objects" do
    expect_evaluate_ruby do
      debugger
      "hello".to_key == "hello"
    end.to be_truthy
  end

  it "to_key return 'self' for Number objects" do
    expect_evaluate_ruby do
      12.to_key == 12
    end.to be_truthy
  end

  it "to_key return 'self' for Boolean objects" do
    expect_evaluate_ruby do
      true.to_key == true && false.to_key == false
    end.to be_truthy
  end
  
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
    expect(page).to have_content('to key was called!')
  end
end
