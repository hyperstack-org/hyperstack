require 'spec_helper'

describe "edge cases" do

  before(:each) do
    React::IsomorphicHelpers.load_context
  end

  it "base and subclass both belong to same parent record"
  it "will set changed on the parent record when updating a child aggregate"

  it "knows a targets owner before loading" do
    React::IsomorphicHelpers.load_context
    expect(User.find_by_email("mitch@catprint.com").todo_items.first.user.email).to eq("mitch@catprint.com")
  end

  it "can return a nil association" do
    ReactiveRecord.load do
      TodoItem.all.collect do |todo|
        todo.comment and todo.comment.comment
      end.compact
    end.then do |collection|
      expect(collection).to be_empty
    end
  end

  async "reruns loads in order" do
    User.find_by_email("mitch@catprint.com").last_name
    after(0.01) do
      ReactiveRecord.load do
        TodoItem.find_by_title("do it again Todd").description
      end.then do |description|
        async { expect(description).to eq("Todd please do that great thing you did again") }
      end
    end
  end

  async "will load the same record via two different methods" do
    ReactiveRecord.load do
      # first load a record one way
      # on load retry we want to just insure the contents are loaded, but we are still pointing the same instance
      @r1 ||= User.find_by_email("mitch@catprint.com")
      @r1.address.zip # just so we grab something that is not the id
      @r1
    end.then do |r1|
      ReactiveRecord.load do
        # now repeat but get teh record a different way, this will return a different instance
        @r2 ||= User.find_by_first_name("Mitch")
        @r2.last_name # lets get the last name, when loaded the two record ids will match and will be merged
        @r2
      end.then do |r2|
        async do
          expect(r1.last_name).to eq(r2.last_name)
          expect(r1).to eq(r2)
          expect(r1).not_to be(r2)
        end
      end
    end
  end

  async "will load the same record via two different methods via a collection" do
    ReactiveRecord.load do
      # first load a record one way
      # on load retry we want to just insure the contents are loaded, but we are still pointing the same instance
      @r1 ||= User.find_by_email("mitch@catprint.com").todo_items.first
      @r1.title # just so we grab something that is not the id
      @r1
    end.then do |r1|
      ReactiveRecord.load do
        # now repeat but get teh record a different way, this will return a different instance
        @r2 ||= TodoItem.find_by_title("#{r1.title}") # to make sure there is no magic lets make the title into a new string
        @r2.description # lets get the description, when loaded the two record ids will match and will be merged
        @r2
      end.then do |r2|
        async do
          expect(r1.description).to eq(r2.description)
          expect(r1).to eq(r2)
          expect(r1).not_to be(r2)
        end
      end
    end
  end

  async "will load a record by indexing a collection" do
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").todo_items.collect { |todo| todo.description }
    end.then do |descriptions|
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find_by_email("mitch@catprint.com").todo_items[1].description
      end.then do |description|
        async { expect(description).to eq(descriptions[1]) }
      end
    end
  end

  it "will load nested collections correctly" do
    ReactiveRecord.load do
      User.find_by_email("test1@catprint.com").todo_items.collect do |todo|
        todo.comments.collect do |comment|
          comment.comment
        end
      end
    end.then do | comments |
      expect(comments).to eq([["test 1 todo 1 comment 1", "test 1 todo 1 comment 2"],["test 1 todo 2 comment 1", "test 1 todo 2 comment 2"]])
    end
  end

  async "will not fetch model.all when saving a new record to the model" do
    (new_record = User.new(email: "test22@catprint.com")).save do
      new_record.destroy.then do
        async { expect(ReactiveRecord::Base.class_scopes(User)[:all]).to be_nil }
      end
    end
  end
end
