require 'spec_helper'

describe "can scope models" do

  it "scopes todos by string" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").todo_items.find_string("mitch").first.title
    end.then do |title|
      expect(title).to be("a todo for mitch")
    end
  end

  it "can apply multiple simple scopes" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").todo_items.active.important.first.title
    end.then do |title|
      expect(title).to be("another todo for mitch")
    end
  end

  it "can apply multiple scopes" do
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").todo_items.find_string("mitch").find_string("another").count
    end.then do |count|
      expect(count).to be(1)
    end
  end

  it "can apply scopes to model" do
    ReactiveRecord.load do
      TodoItem.find_string("mitch").first.title
    end.then do |title|
      expect(title).to be("a todo for mitch")
    end
  end

  it "works for an empty set" do
    ReactiveRecord.load do
      User.find_by_email("adamg@catprint.com").todo_items.find_string("mitch").find_string("another").collect do |item|
        item.title
      end
    end.then do |result|
      expect(result).to eq([])
    end
  end


  it "works for an empty set even if other items are retrieved" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      user = User.find(3)
      user.todo_items.find_string("mitch").find_string("another").collect do |item|
        item.title
      end
    end.then do |result|
      expect(result).to eq([])
    end
  end

  it "reports that a collection is loading" do
    React::IsomorphicHelpers.load_context
    expect(User.find_by_email("mitch@catprint.com").todo_items).to be_loading
  end

  it "reports that a collection has loaded" do
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").todo_items.first.title
    end.then do |title|
      expect(User.find_by_email("mitch@catprint.com").todo_items).to be_loaded
    end
  end

  it "can return the count of a collection without loading the collection" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").todo_items.count
    end.then do |count|
      expect(count).to be(2)
      expect(User.find_by_email("mitch@catprint.com").todo_items).to be_loading
    end
  end # BROKEN BROKEN BROKEN

end
