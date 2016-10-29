require 'spec_helper'

describe "updating aggregations" do

  before(:all) do
    React::IsomorphicHelpers.load_context
    User.new({first_name: "Jon", last_name: "Weaver"})
  end

  it "a hash can be assigned to initialize an aggregate" do
    expect(User.new(address: Address.new(zip:12345)).address.zip).to eq(12345)
  end

  it "a new model will have a blank aggregate" do
    expect(User.find_by_first_name("Jon").address.attributes[:zip]).to be_blank
  end

  it "an aggregate can be updated through the parent model" do
    User.find_by_first_name("Jon").address.zip = "14609"
    expect(User.find_by_first_name("Jon").address.zip).to eq("14609")
  end

  async "saving a model, saves the aggregate values" do
    User.find_by_first_name("Jon").save.then do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find_by_first_name("Jon").address.zip
      end.then do |zip|
        async { expect(zip).to eq("14609") }
      end
    end
  end

  it "an aggregate can be assigned" do
    user = User.find_by_first_name("Jon")
    user.address = Address.new({zip: "14622", city: "Rochester"})
    expect([user.address.zip, user.address.city]).to eq(["14622", "Rochester"])
  end

  async "and saving the model will save the address" do
    User.find_by_first_name("Jon").save.then do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        [User.find_by_first_name("Jon").address.zip, User.find_by_first_name("Jon").address.city]
      end.then do |zip_and_city|
        async { expect(zip_and_city).to eq(["14622", "Rochester"]) }
      end
    end
  end

  it "two aggregates of the same type don't not get mixed up" do
    ReactiveRecord.load do
      User.find_by_first_name("Jon").address2.zip
    end.then do |zip|
      expect(zip).to be_nil
    end
  end

  async "can assign a model to an aggregate attribute" do
    address = Address.new({zip: "14622", city: "Rochester"})
    address.save do
      user = User.new
      user.address = address
      ReactiveRecord.load do
        user.verify_zip
      end.then do |value|
        async { expect(value).to eq("14622") }
      end
    end
  end

  after(:all) do
    Promise.when(Address.all.last.destroy, User.find_by_first_name("Jon").destroy)
  end

end
