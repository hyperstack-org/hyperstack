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
end
