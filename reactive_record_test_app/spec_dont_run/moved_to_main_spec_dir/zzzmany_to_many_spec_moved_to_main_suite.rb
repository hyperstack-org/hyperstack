require 'spec_helper'

describe "many to many associations" do

  it "it is time to count some comments" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      TodoItem.find_by_title("a todo for mitch").comments.count
    end.then do |count|
      expect(count).to be(1)
    end
  end

  it "is time to see who made the comment" do
    ReactiveRecord.load do
      TodoItem.find_by_title("a todo for mitch").comments.first.user.email
    end.then do |email|
      expect(email).to eq("adamg@catprint.com")
    end
  end

  it "is time to get it directly through the relationship" do
    ReactiveRecord.load do
      TodoItem.find_by_title("a todo for mitch").commenters.first.email
    end.then do |email|
      expect(email).to eq("adamg@catprint.com")
    end
  end

end
