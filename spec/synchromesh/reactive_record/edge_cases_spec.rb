# it "trims the association tree" do
#   ReactiveRecord.load do
#     TodoItem.all.collect do |todo|
#       todo.user && todo.user.first_name
#     end.compact
#   end.then do |first_names|
#     expect(first_names.count).to eq(5)
#   end
# end

require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "reactive-record edge cases", js: true do

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

  it "trims the association tree" do
    5.times do |i|
      user = FactoryGirl.create(:user, first_name: i) unless i == 3
      FactoryGirl.create(:todo, title: "User #{i}'s todo", owner: user)
    end
    expect_promise do
      ReactiveRecord.load do
        Todo.all.collect do |todo|
          todo.owner && todo.owner.first_name
        end.compact
      end
    end.to contain_exactly('0', '1', '2', '4')
  end
end
