require 'spec_helper'
require 'hyper-trace'

# for testing convienience we do an odd thing:  if acting_user is nil we treat it as a super user
# other wise we can provide an email which will be converted by the application controller into the acting_user

describe "checking permissions" do

  it "will use the default permissions" do
    React::IsomorphicHelpers.load_context
    set_acting_user "super-user"
    ReactiveRecord.load do
      User.find_by_email("todd@catprint.com").id
    end.then do |id|
      expect(id).not_to be_nil
    end
  end

  it "will reject a view by the wrong user" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do |failure|
      if failure
        failure
      else
       set_acting_user "todd@catprint.com"
        User.find_by_email("mitch@catprint.com").id
      end
    end.then do |failure|
      set_acting_user "super-user"
      expect(failure).to include("ReactiveRecord::AccessViolation")
    end
  end

  it "will honor a correct view permission" do
    ReactiveRecord.load do
      set_acting_user 'mitch@catprint.com'
      User.find_by_first_name("Mitch").last_name
    end.then do |last_name|
      set_acting_user "super-user"
      expect(last_name).to eq("VanDuyn")
    end
  end

  it "will show data if the user is correct" do
    ReactiveRecord.load do
      set_acting_user 'mitch@catprint.com'
      TodoItem.find_by_title("a todo for mitch").description
    end.then do |description|
      set_acting_user "super-user"
      expect(description).not_to be_nil
    end
  end

  it "will not show data if the user is not correct" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do |failure|
      if failure
        failure
      else
        set_acting_user 'todd@catprint.com'
        TodoItem.find_by_title("a todo for mitch").description
      end
    end.then do |failure|
      set_acting_user "super-user"
      expect(failure).to include("ReactiveRecord::AccessViolation")
    end
  end

  it "is time to make sure mitch is loaded" do
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").todo_items.collect { |todo| todo.title }
    end.then do |todos|
      expect(todos).not_to be_nil
    end
  end

  it "is time to give mitch a new todo" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.todo_items << TodoItem.new({title: "new todo for you"})
    mitch.save.then { |result| expect(result[:success]).to be_truthy }
  end

  it "should let mitch update the description" do
    new_todo = TodoItem.find_by_title("new todo for you")
    new_todo.description = "blah blah blah"
    set_acting_user 'mitch@catprint.com'
    new_todo.save.then do |result|
      expect(result[:success]).to be_truthy
    end
  end

  it "should not let somebody else update the description" do
    new_todo = TodoItem.find_by_title("new todo for you")
    new_todo.description = "I can't do this..."
    set_acting_user 'todd@catprint.com'
    new_todo.save.then do |result|
      expect(result[:success]).to be_falsy
    end
  end

  async "should let users add their own comment (tests create_permitted)" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      set_acting_user "super-user"
      TodoItem.find_by_title("new todo for you").comments.all
      User.find_by_email("todd@catprint.com").id
    end.then do
      new_todo = TodoItem.find_by_title("new todo for you")
      new_todo.comments << Comment.new({comment: "a comment", user: User.find_by_email("todd@catprint.com")})
      set_acting_user 'todd@catprint.com'
      new_todo.save.then do |result|
        async { expect(result[:success]).to be_truthy }
      end
    end
  end

  async "should not let a user add another user's comment (tests create_permitted)" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      set_acting_user "super-user"
      TodoItem.find_by_title("new todo for you").comments.count # should be count
      User.find_by_email("todd@catprint.com").id
    end.then do
      new_todo = TodoItem.find_by_title("new todo for you")
      new_todo.comments << Comment.new({comment: "another comment", user: User.find_by_email("todd@catprint.com")})
      set_acting_user 'mitch@catprint.com'
      new_todo.save.then do |result|
        async { expect(result[:success]).to be_falsy }
      end
    end
  end

  it "is time to make sure things really did work" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      set_acting_user "super-user"
      todo = TodoItem.find_by_title("new todo for you")
      [todo.user.first_name, todo.description, todo.comments.count, todo.comments.first.comment, todo.comments.first.user.email]
    end.then do |results|
      expect(results).to eq(["Mitch", "blah blah blah", 1, "a comment", "todd@catprint.com"])
    end
  end

  it "is time to delete the comment - lets see if mitch can delete it" do
    comment = TodoItem.find_by_title("new todo for you").comments.first
    set_acting_user 'mitch@catprint.com'
    comment.destroy.then { |result| expect(result[:success]).to be_falsy }
  end

  async "is time to delete the comment - lets do it without the promise" do
    React::IsomorphicHelpers.load_context
    comment = TodoItem.find_by_title("new todo for you").comments.first
    set_acting_user 'mitch@catprint.com'
    comment.destroy { |result, message| async { expect(result).to be_falsy; expect(message).to be_present } }
  end

  it "is time to really delete it" do
    React::IsomorphicHelpers.load_context
    set_acting_user 'todd@catprint.com'
    comment = Comment.find_by_comment("a comment")
    comment.destroy.then { |result| expect(result[:success]).to be_truthy }
  end

  it "is time to delete the todo" do
    set_acting_user "super-user"
    new_todo = TodoItem.find_by_title("new todo for you")
    new_todo.destroy.then { |result| expect(result[:success]).to be_truthy }
  end

end
