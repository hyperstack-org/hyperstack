require 'spec_helper'
#require 'user'
#require 'todo_item'
#require 'address'

describe "integration with react" do

  before(:each) { React::IsomorphicHelpers.load_context }

  it "find by two methods will not give the same object until loaded" do
    r1 = User.find_by_email("mitch@catprint.com")
    r2 = User.find_by_first_name("Mitch")
    expect(r1).not_to eq(r2)
  end

  rendering("find by two methods gives same object once loaded") do
    r1 = User.find_by_email("mitch@catprint.com")
    r2 = User.find_by_first_name("Mitch")
    r1.id
    r2.id
    if r1 == r2
      "SAME OBJECT"
    else
      "NOT YET"
    end
  end.should_generate do
    html == "SAME OBJECT"
  end

  it "will find two different attributes will not be equal before loading" do
    r1 = User.find_by_email("mitch@catprint.com")
    expect(r1.first_name).not_to eq(r1.last_name)
  end

  it "will find the same attributes to be equal before loading" do
    r1 = User.find_by_email("mitch@catprint.com")
    expect(r1.first_name).to eq(r1.first_name)
  end

  rendering("find by two methods gives same attributes once loaded") do
    r1 = User.find_by_email("mitch@catprint.com")
    r2 = User.find_by_first_name("Mitch")
    if r1.first_name == r2.first_name
      "SAME VALUE"
    else
      "NOT YET"
    end
  end.should_generate do
    html == "SAME VALUE"
  end

  it "will know that an attribute is loading" do
    r1 = User.find_by_email("mitch@catprint.com")
    expect(r1.first_name).to be_loading
  end

  rendering("an attribute will eventually set it not loading") do
    User.find_by_email("mitch@catprint.com").first_name.loading? ? "LOADING" : "LOADED"
  end.should_generate do
    html == "LOADED"
  end

  it "will know that an attribute is not loaded" do
    r1 = User.find_by_email("mitch@catprint.com")
    expect(r1.first_name).not_to be_loaded
  end

  rendering("an attribute will eventually set it loaded") do
    User.find_by_email("mitch@catprint.com").first_name.loaded? ? "LOADED" : "LOADING"
  end.should_generate do
    html == "LOADED"
  end

  it "present? returns true for a non-nil value" do
    expect("foo").to be_present
  end

  it "present? returns false for nil" do
    expect(false).not_to be_present
  end

  it "will consider a unloaded attribute not to be present" do
    r1 = User.find_by_email("mitch@catprint.com")
    expect(r1.first_name).not_to be_present
  end

  rendering("a non-nil attribute will make it present") do
    User.find_by_email("mitch@catprint.com").first_name.present? ? "PRESENT" : ""
  end.should_generate do
    html == "PRESENT"
  end

  rendering("a simple find_by query") do
    User.find_by_email("mitch@catprint.com").email
  end.should_immediately_generate do
    html == "mitch@catprint.com"
  end

  rendering("an attribute from the server") do
    User.find_by_email("mitch@catprint.com").first_name
  end.should_generate do
    html == "Mitch"
  end

  rendering("a has_many association") do
    User.find_by_email("mitch@catprint.com").todo_items.collect do |todo|
      todo.title
    end.join(", ")
  end.should_generate do
    html == "a todo for mitch, another todo for mitch"
  end

  rendering("only as many times as needed") do
    times_up = React::State.get_state(self, "times_up")
    @timer ||= after(0.5) { React::State.set_state(self, "times_up", "DONE")}
    @count ||= 0
    @count += 1
    "#{times_up} #{@count.to_s} " + User.find_by_email("mitch@catprint.com").todo_items.collect do |todo|
      todo.title
    end.join(", ")
  end.should_generate do
    puts "trying again: #{html}"
    html == "DONE 3 a todo for mitch, another todo for mitch"
  end

  rendering("a belongs_to association from id") do
    TodoItem.find(1).user.email
  end.should_generate do
    html == "mitch@catprint.com"
  end

  rendering("a belongs_to association from an attribute") do
    User.find_by_email("mitch@catprint.com").todo_items.first.user.email
  end.should_generate do
    html == "mitch@catprint.com"
  end

  rendering("an aggregation") do
    User.find_by_email("mitch@catprint.com").address.city
  end.should_generate do
    html == "Rochester"
  end

  rendering("a record that is updated multiple times") do
    unless @record
      @record = User.new
      @record.attributes[:all_done] = false
      @record.attributes[:test_done] = false
      @record.attributes[:counter] = 0
    end
    after(0.1) do
      puts "update counter timer expired, @record.test_done = #{!!@record.test_done}"
      @record.counter = @record.counter + 1 unless @record.test_done
    end
    puts "record.changed? #{!!@record.changed?}"
    after(2) do
      puts "all done timer expired test should get done now!"
      @record.all_done = true
    end unless @record.changed?
    if @record.all_done
      @record.all_done = nil
      @record.test_done = true
      "#{@record.counter}"
    else
      "not done yet... #{@record.changed?}, #{@record.attributes[:counter]}"
    end
  end.should_generate do
    puts "html = #{html}"
    html == "2"
  end

  rendering("changing an aggregate is noticed by the parent") do
    @user ||= User.find_by_email("mitch@catprint.com")
    after(0.1) do
      @user.address.city = "Timbuktoo"
    end
    if @user.changed?
      "#{@user.address.city}"
    end
  end.should_generate do
    html == "Timbuktoo"
  end

  rendering("a server side value dynamically changed before first fetch from server") do
    puts "rendering"
    @update ||= after(0.001) do
      puts "async update"
      mitch = User.find_by_email("mitch@catprint.com")
      mitch.first_name = "Robert"
      mitch.detailed_name!
      puts "updated"
    end
    User.find_by_email("mitch@catprint.com").detailed_name
  end.should_generate do
    puts "html = #{html}"
    html == "R. VanDuyn - mitch@catprint.com (2 todos)"
  end
  
  rendering("a server side value dynamically changed after first fetch from server") do
    puts "rendering"
    @render_times ||= 0
    @render_times += 1
    after(1) do
      puts "async update"
      mitch = User.find_by_email("mitch@catprint.com")
      mitch.first_name = "Robert"
      puts "mitch.detailed_name BEFORE = #{mitch.detailed_name}"
      mitch.detailed_name!
      puts "mitch.detailed_name AFTER = #{mitch.detailed_name}"
      puts "updated"
    end if @render_times == 2
    User.find_by_email("mitch@catprint.com").detailed_name
  end.should_generate do
    puts "html = #{html}"
    if html == "R. VanDuyn - mitch@catprint.com (2 todos)"
      true
    end
  end

  rendering('cleanup') do
    times_up = React::State.get_state(self, "times_up")
    @timer ||= after(0.5) { React::State.set_state(self, "times_up", "DONE")}
    @count ||= 0
    @count += 1
    "#{times_up}#{@count}"
  end.should_generate do
    html == "DONE2"
  end

end
