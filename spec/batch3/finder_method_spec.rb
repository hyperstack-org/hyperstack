require 'spec_helper'
require 'test_components'
require 'rspec-steps'


RSpec::Steps.steps "finder_method", js: true do

  before(:step) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
    end
    isomorphic do
      Todo.class_eval do
        class << self
          attr_accessor :current_random_value
        end
        finder_method :random_item do |i|
          find(current_random_value + i.to_i)
        end
        scope :test_scope, -> { all }
      end
    end
    size_window(:small, :portrait)
    5.times { FactoryGirl.create(:todo) }
  end

  it "returns the correct value" do
    Todo.current_random_value = 1
    expect_promise do
      HyperMesh.load { Todo.random_item(2) }.then { |todo| todo.id }
    end.to eq(3)
  end

  it "returns the correct value on the server too" do
    Todo.current_random_value = 1
    expect(Todo.random_item(2).id).to eq(3)
  end

  it "will not reload the value unless forced" do
    Todo.current_random_value = 2
    expect_promise do
      HyperMesh.load { Todo.random_item(2) }.then { |todo| todo.id }
    end.to eq(3)
  end

  it "can be forced to reload the value" do
    expect_promise do
      current_value = Todo.random_item(2).id
      HyperMesh.load do
        new_value = Todo.random_item(2).id
        Todo.random_item!(2) if current_value == new_value
        new_value
      end
    end.to eq(4)
  end

  it "can apply to a nested scope" do
    expect_promise do
      HyperMesh.load { Todo.test_scope.random_item(2) }.then { |todo| todo.id }
    end.to eq(4)
  end
end
