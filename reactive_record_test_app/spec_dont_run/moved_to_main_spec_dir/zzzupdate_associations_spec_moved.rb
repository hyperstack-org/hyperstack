require 'spec_helper'

describe "updating associations" do

  before(:all) do
    React::IsomorphicHelpers.load_context
    User.new({first_name: "Jon", last_name: "Weaver"})
  end

  it "a new model will have empty has_many assocation" do
    jon =  User.find_by_first_name("Jon")
    expect(jon.todo_items).to be_empty
  end

  it "an item can be added to a has_many association" do
    jon = User.find_by_first_name("Jon")
    result = (jon.todo_items << (item = TodoItem.new({title: "Jon's first todo!"})))
    expect(result).to be(jon.todo_items)
    expect(jon.todo_items.count).to be(1)
  end

  async "it will persist the new has_many association" do
    User.find_by_first_name("Jon").save do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find_by_first_name("Jon").todo_items.count
      end.then do | count |
        async { expect(count).to be(1) }
      end
    end
  end

  it "and will reconstruct the association and values on reloading" do
    ReactiveRecord.load do
      User.find_by_first_name("Jon").todo_items.collect { | todo | todo.title }
    end.then do | titles |
      expect(titles).to eq(["Jon's first todo!"])
    end
  end # BROKEN BROKEN

  it "the inverse belongs_to association will be set" do
    todo = TodoItem.find_by_title("Jon's first todo!")
    expect(todo.user.first_name).to eq("Jon")
  end

  it "a model can be moved to a new owner, and will be removed from the old owner" do
    TodoItem.find_by_title("Jon's first todo!").user = User.new({first_name: "Jan", last_name: "VanDuyn"})
    expect(User.find_by_first_name("Jon").todo_items).to be_empty
  end

  it "and will belong to the new owner" do
    expect(User.find_by_first_name("Jan").todo_items.all == [TodoItem.find_by_title("Jon's first todo!")]).to be_truthy
  end

  async "and can be saved and it will remember its new owner" do
    TodoItem.find_by_title("Jon's first todo!").save do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        TodoItem.find_by_title("Jon's first todo!").user.first_name
      end.then do | first_name |
        async { expect(first_name).to be("Jan") }
      end
    end
  end # MAYBE BROKEN PREVIOUS BREAK CAUSING????

  it "and after saving will have been removed from original owners association" do
    ReactiveRecord.load do
      User.find_by_first_name("Jon").todo_items.all
    end.then do | todos |
      expect(todos).to be_empty
    end
  end

  it "a belongs to association can be set to nil and the model saved" do
    todo = TodoItem.find_by_title("Jon's first todo!")
    todo.user = nil
    todo.save.then do | response |
      expect(response[:success]).to be_truthy
    end
  end

  it "and will not belong to the previous owner anymore" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      TodoItem.find_by_title("Jon's first todo!").user # load the todo in prep for the next test
      User.find_by_first_name("Jan").todo_items.all.count
    end.then do |count|
      expect(count).to be(0)
    end
  end

  it "but can be reassigned to the previous owner" do
    todo = TodoItem.find_by_title("Jon's first todo!")
    todo.user = User.find_by_first_name("Jan")
    todo.save.then do | response |
      expect(response[:success]).to be_truthy
    end
  end

  it "and a model in a belongs_to relationship can be deleted" do
    User.find_by_first_name("Jan").todo_items.first.destroy.then do
      expect(User.find_by_first_name("Jan").todo_items).to be_empty
    end
  end

  it "and it won't exist" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      TodoItem.find_by_title("Jon's first todo!").id
    end.then do | id |
      expect(id).to be_nil
    end
  end

  it "an item in a belongs_to relationship can be created without belonging to anybody" do
    nobodys_business = TodoItem.new({title: "round to it"})
    nobodys_business.save.then do |saved|
      expect(saved).to be_truthy
    end
  end

  it "and can be reloaded" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      TodoItem.find_by_title("round to it").id
    end.then do |id|
      expect(id).not_to be_nil
    end
  end

  it "and can be deleted" do
    TodoItem.find_by_title("round to it").destroy.then do
      expect(TodoItem.find_by_title("round to it")).to be_destroyed
    end
  end

  after(:all) do
    Promise.when(User.find_by_first_name("Jan").destroy, User.find_by_first_name("Jon").destroy)
  end


end
