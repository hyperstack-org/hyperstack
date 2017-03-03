require 'spec_helper'
require 'test_components'

describe "save while loading", js: true do

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      #allow_change(to: User, on: [:update]) { true }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it "with new and create" do
    user = FactoryGirl.create(:user, first_name: 'Ima')
    expect_promise do
      TodoItem.create(user: User.find_by_first_name('Ima'))
    end.to include('success' => true)
    expect(user.todo_items).to eq([TodoItem.first])
  end
  it "with push" do
    user = FactoryGirl.create(:user, first_name: 'Ima')
    expect_promise do
      User.find(1).todo_items << TodoItem.new
      User.find(1).save
    end.to include('success' => true)
    expect(user.todo_items).to eq([TodoItem.first])
  end
  it "with assignment" do
    user = FactoryGirl.create(:user, first_name: 'Ima')
    expect_promise do
      todo = TodoItem.new
      todo.user = User.find_by_first_name('Ima')
      todo.save
    end.to include('success' => true)
    expect(user.todo_items).to eq([TodoItem.first])
  end
end
