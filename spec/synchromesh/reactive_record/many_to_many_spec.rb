require 'spec_helper'
require 'synchromesh/integration/test_components'
require 'synchromesh/reactive_record/factory'

describe "many to many associations", js: true do

  before(:each) do
    seed_database
  end

  before(:each) do
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

  it "does not effect the base relationship count" do
    expect_promise do
      ReactiveRecord.load do
        TodoItem.find_by_title("a todo for mitch").comments.count
      end
    end.to be(1)
  end

  it "does not effect access to attributes in the base relationship" do
    expect_promise do
      ReactiveRecord.load do
        TodoItem.find_by_title("a todo for mitch").comments.count
      end.then do
        ReactiveRecord.load do
          TodoItem.find_by_title("a todo for mitch").comments.first.user.email
        end
      end
    end.to eq("adamg@catprint.com")
  end

  it "can be followed directly" do
    expect_promise do
      ReactiveRecord.load do
        TodoItem.find_by_title("a todo for mitch").commenters.first.email
      end
    end.to eq("adamg@catprint.com")
  end
end
