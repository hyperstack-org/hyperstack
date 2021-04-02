require 'spec_helper'
require 'test_components'
require 'reactive_record_factory'
require 'rspec-steps'

RSpec::Steps.steps "updating associations", js: true do

  before(:all) do
    seed_database
    Hyperstack.transport = :none
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

  it "a new model will have empty has_many assocation" do
    expect_evaluate_ruby do
      User.new({first_name: "Jon", last_name: "Weaver"})
      User.find_by_first_name("Jon").todo_items.all
    end.to be_empty
  end

  it "the push operator returns the collection" do
    expect_evaluate_ruby do
      jon = User.find_by_first_name("Jon")
      result = (jon.todo_items << (item = TodoItem.new({title: "Jon's first todo!"})))
      result == jon.todo_items
    end.to be_truthy
  end

  it "the push operator adds 1 to the count" do
    expect_evaluate_ruby do
      User.find_by_first_name("Jon").todo_items.count
    end.to be(1)
  end

  it "will persist the new has_many association" do
    evaluate_ruby do
      User.find_by_first_name("Jon").save
    end
    wait_for { User.find_by_first_name("Jon").todo_items.count rescue nil }.to eq(1)
  end

  it "and will reconstruct the association and values on reloading" do
    expect_promise do
      Hyperstack::Component::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find_by_first_name("Jon").todo_items.collect { | todo | todo.title }
      end
    end.to eq(["Jon's first todo!"])
  end

  it "the inverse belongs_to association will be set" do
    expect_evaluate_ruby do
      todo = TodoItem.find_by_title("Jon's first todo!")
      todo.user.first_name
    end.to eq("Jon")
  end

  it "a model can be moved to a new owner, and will be removed from the old owner" do
    expect_evaluate_ruby do
      TodoItem.find_by_title("Jon's first todo!").user = User.new({first_name: "Jan", last_name: "VanDuyn"})
      User.find_by_first_name("Jon").todo_items.all
    end.to be_empty
  end

  it "and will belong to the new owner" do
    expect_evaluate_ruby do
      User.find_by_first_name("Jan").todo_items.all == [TodoItem.find_by_title("Jon's first todo!")]
    end.to be_truthy
  end

  it "and can be saved and it will remember its new owner" do
    evaluate_ruby do
      TodoItem.find_by_title("Jon's first todo!").save
    end
    wait_for { TodoItem.find_by_title("Jon's first todo!").user.first_name rescue nil }.to eq('Jan')
  end

  it "and after saving will have been removed from original owners association" do
    expect(User.find_by_first_name("Jon").todo_items).to be_empty
  end

  it "a belongs to association can be set to nil and the model saved" do
    expect_promise do
      Hyperstack::Component::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        TodoItem.find_by_title("Jon's first todo!").tap { | todo | todo.user }
      end.then do | todo |
        todo.user = nil
        todo.save
      end.then do | response |
        response[:success]
      end
    end.to be_truthy
  end

  it "and it will update on the server" do
    expect(TodoItem.find_by_title("Jon's first todo!").user).to be_nil
  end

  it "and will not belong to the previous owner anymore" do
    expect_promise do
      Hyperstack::Component::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find_by_first_name("Jan").todo_items.count
      end
    end.to be(0)
  end

  it "but can be reassigned to the previous owner" do
    expect_promise do
      ReactiveRecord.load do
        TodoItem.find_by_title("Jon's first todo!").tap { | todo | todo.user }
      end.then do | todo |
        todo.user = User.find_by_first_name("Jan")
        todo.save
      end.then do | response |
        response[:success]
      end
    end.to be_truthy
  end

  it "and it will update the server on saving" do
    expect(TodoItem.find_by_title("Jon's first todo!").user.first_name).to eq('Jan')
  end

  it "and a model in a belongs_to relationship can be destroyed" do
    expect do
      ReactiveRecord.load do
        User.find_by_first_name("Jan").todo_items.collect { |item| item.itself }.first
      end.then do | first |
        first.destroy.then do |response|
          User.find_by_first_name("Jan").todo_items.all
        end.tap { @was_destroyed_already = first.destroyed? }
      end
    end.on_client_to
    # added to check that issue #119 got fixed.  Item is not
    # considered destroyed until we get the status back from server
    # that it was destroyed
    expect { @was_destroyed_already }.on_client_to be_falsy
  end

  it "will update the server properly" do
    expect(User.find_by_first_name("Jan").todo_items).to be_empty
  end

  it "and it won't exist after being destroyed" do
    expect_promise do
      Hyperstack::Component::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        TodoItem.find_by_title("Jon's first todo!")
      end
    end.to be_nil
  end

  it "an item in a belongs_to relationship can be created without belonging to anybody" do
    expect_promise do
      TodoItem.new({title: "round to it"}).save
    end.to be_truthy
  end

  it "and can be reloaded" do
    expect_promise do
      Hyperstack::Component::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        TodoItem.find_by_title("round to it").id.to_i
      end
    end.to eq(TodoItem.find_by_title("round to it").id)
  end

  it "and can be deleted" do
    expect_promise do
      TodoItem.find_by_title("round to it").destroy.then do
        TodoItem.find_by_title("round to it")
      end
    end.to be_nil
  end

  it "and it will be won't exist the server" do
    expect(TodoItem.find_by_title('round to it')).to be_nil
  end

end
