require 'spec_helper'

describe "creating and updating a record" do

  before(:all) do
    React::IsomorphicHelpers.load_context
  end

  it "can create a new record" do
    jon = User.new({first_name: "Jon", last_name: "Weaver"})
    expect(jon.attributes).to eq({first_name: "Jon", last_name: "Weaver"})
  end

  it "after creating it will have no id" do
    jon = User.find_by_first_name("Jon")
    expect(jon.id).to be_nil
  end

  it "after creating it will be new" do
    jon = User.find_by_first_name("Jon")
    expect(jon).to be_new
  end

  it "after creating it will be changed" do
    jon = User.find_by_first_name("Jon")
    expect(jon.changed?).to be_truthy
  end

  it "it can calculate server side attributes before saving" do
    ReactiveRecord.load do
      User.find_by_first_name("Jon").detailed_name
    end.then do |name|
      expect(name).to eq("J. Weaver")
    end
  end

  it "can be saved and will have an id" do
    jon = User.find_by_first_name("Jon")
    jon.save.then { expect(jon.id).not_to be_nil }
  end

  it "can be reloaded" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_first_name("Jon").last_name
    end.then do |last_name|
      expect(last_name).to be("Weaver")
    end
  end

  it "will still have an id" do
    jon = User.find_by_first_name("Jon")
    expect(jon.id).not_to be_nil
  end

  it "can be updated and it will get new server side values before saving" do
    jon = User.find_by_last_name("Weaver")
    jon.email = "jonny@catprint.com"
    ReactiveRecord.load do
      jon.detailed_name
    end.then do |detailed_name|
      expect(detailed_name).to eq("J. Weaver - jonny@catprint.com")
    end
  end

  it "can be updated but it won't see the new server side values" do
    jon = User.find_by_last_name("Weaver")
    jon.email = "jon@catprint.com"
    ReactiveRecord.load do
      jon.detailed_name
    end.then do |detailed_name|
      expect(detailed_name).to eq("J. Weaver - jonny@catprint.com")
    end
  end

  it "but the bang method forces a refresh" do
    jon = User.find_by_last_name("Weaver")
    ReactiveRecord.load do
      jon.detailed_name! unless jon.detailed_name == "J. Weaver - jon@catprint.com"
      jon.detailed_name
    end.then do |detailed_name|
      expect(detailed_name).to eq("J. Weaver - jon@catprint.com")
    end
  end

  async "can be saved and will remember the new values" do
    jon = User.find_by_last_name("Weaver")
    jon.email = "jon@catprint.com"
    jon.save.then do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find_by_last_name("Weaver").email
      end.then do |email|
        async { expect(email).to be("jon@catprint.com") }
      end
    end
  end

  it "can be deleted" do
    jon = User.find_by_last_name("Weaver")
    jon.destroy.then { expect(jon.id).to be_nil }
  end

  it "does not exist in the database" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_first_name("Jon").id
    end.then do |id|
      expect(id).to be_nil
    end
  end

  async "it can have a one way writable attribute (might be used for a password - see the user model)" do
    jon = User.new({name: "Jon Weaver"})
    jon.save.then do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find_by_last_name("Weaver").first_name
      end.then do |first_name|
        async { expect(first_name).to be("Jon") }
      end
    end
  end

  async "load method with no block and one attribute" do
    React::IsomorphicHelpers.load_context
    user = User.find_by_email("mitch@catprint.com")
    user.first_name = "Robert"
    user.todo_items << TodoItem.new(title: "test")
    user.load(:detailed_name).then do |detailed_name|
      async do
        expect(detailed_name).to be("R. VanDuyn - mitch@catprint.com (3 todos)")
      end
    end
  end #BROKEN BROKEN BROKEN

  async "load method with no block and multiple attributes" do
    React::IsomorphicHelpers.load_context
    user = User.find_by_email("mitch@catprint.com")
    user.first_name = "Robert"
    user.load(:detailed_name, :name).then do |detailed_name, name|
      async do
        expect(detailed_name).to be("R. VanDuyn - mitch@catprint.com (2 todos)")
        expect(name).to be("Robert VanDuyn")
      end
    end
  end

  async "load method with a block and one attribute" do
    React::IsomorphicHelpers.load_context
    loop_count = 0
    user = User.find_by_email("mitch@catprint.com")
    user.first_name = "Robert"
    user.load(:detailed_name) do |detailed_name|
      loop_count += 1
      detailed_name
    end.then do |detailed_name|
      async do
        expect(loop_count).to eq(2)
        expect(detailed_name).to be("R. VanDuyn - mitch@catprint.com (2 todos)")
      end
    end
  end

  async "load method with a block and multiple attributes" do
    React::IsomorphicHelpers.load_context
    loop_count = 0
    user = User.find_by_email("mitch@catprint.com")
    user.first_name = "Robert"
    user.load(:detailed_name, :name) do |*args|
      loop_count += 1
      args
    end.then do |detailed_name, name|
      async do
        expect(loop_count).to eq(2)
        expect(detailed_name).to be("R. VanDuyn - mitch@catprint.com (2 todos)")
        expect(name).to be("Robert VanDuyn")
      end
    end
  end

  after(:all) do
    User.find_by_last_name("Weaver").destroy
  end

end
