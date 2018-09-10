require 'spec_helper'
require 'test_components'
require 'reactive_record_factory'
require 'rspec-steps'

RSpec::Steps.steps "reverting records", js: true do

  before(:all) do
    seed_database
  end

  before(:step) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it "finds that the user Adam has not changed yet" do
    expect_promise do
      ReactiveRecord.load do
        User.find_by_first_name("Adam")
      end.then { |u| u.changed? }
    end.to be_falsy
  end

  it "creates a new todo which should be changed (because its new)" do
    expect_evaluate_ruby do
      TodoItem.new({title: "Adam is not getting this todo"}).changed?
    end.to be_truthy
  end

  it "adds the todo to adam's todos and expects adam to change" do
    expect_evaluate_ruby do
      adam = User.find_by_first_name("Adam")
      adam.todo_items << TodoItem.find_by_title("Adam is not getting this todo")
      adam.changed?
    end.to be_truthy
  end

  it "will show that the new todo is still changed" do
    expect_evaluate_ruby do
      TodoItem.find_by_title("Adam is not getting this todo").changed?
    end.to be_truthy
  end

  it "the todo now has an owner" do
    expect_evaluate_ruby do
      TodoItem.find_by_title("Adam is not getting this todo").user
    end.not_to be_nil
  end

  it "can be reverted and the todo will not be changed" do
    expect_evaluate_ruby do
      todo = TodoItem.find_by_title("Adam is not getting this todo")
      todo.revert
      todo.changed?
    end.not_to be_truthy
  end

  it "will not have changed adam" do
    expect_evaluate_ruby do
      User.find_by_first_name("Adam").changed?
    end.not_to be_truthy
  end

  it "is time to test going the other way, lets give adam a todo again" do
    expect_evaluate_ruby do
      new_todo = TodoItem.new({title: "Adam is still not getting this todo"})
      adam = User.find_by_first_name("Adam")
      adam.todo_items << new_todo
      adam.changed?
    end.to be_truthy
  end

  it "can be reverted" do
    expect_evaluate_ruby do
      adam = User.find_by_first_name("Adam")
      adam.revert
      adam.changed?
    end.not_to be_truthy
  end

  it "finds the todo is still changed" do
    expect_evaluate_ruby do
      TodoItem.find_by_title("Adam is still not getting this todo").changed?
    end.to be_truthy
  end

  it "can change an attribute, revert, and make sure nothing else changes" do
    original_count = User.find_by_email("mitch@catprint.com").todo_items.count
    expect_promise do
      mitch = nil
      ReactiveRecord.load do
        mitch = User.find_by_email("mitch@catprint.com")
        mitch.last_name
        mitch.todo_items.count
      end.then do
        mitch.last_name = "xxxx"
        mitch.save
      end.then do
        mitch.revert
        mitch.todo_items.count
      end
    end.to eq(original_count)
  end
end
