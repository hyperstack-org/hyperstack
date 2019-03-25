require 'spec_helper'
require 'rspec-steps'

RSpec::Steps.steps 'using non-ar aggregations', js: true do

  before(:each) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperstack.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end

    User.do_not_synchronize
  end

  before(:step) do
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    ApplicationController.acting_user = nil
  end

  it "create an aggregation" do
    expect_evaluate_ruby do
      User.new(first_name: "Data", data: TestData.new("hello", 3)).data.big_string
    end.to eq("hellohellohello")
  end

  it "save it" do
    evaluate_promise do
      User.find_by_first_name("Data").save
    end
    expect(User.find_by_first_name("Data").data.big_string).to eq("hellohellohello")
    binding.pry
  end

  it "read it" do
    User.create(first_name: 'User2', data: TestData.new('goodby', 3))
    expect_promise do
      ReactiveRecord.load { User.find_by_first_name("User2").data.big_string }
    end.to eq('goodbygoodbygoodby')
  end

  # and restored ...
  #
  # async "is time to change it, and force the save" do
  #   user = User.find_by_first_name("Data")
  #   user.data.string = "goodby"
  #   user.save(force: true).then do
  #     Hyperstack::Component::IsomorphicHelpers.load_context
  #     ReactiveRecord.load do
  #       User.find_by_first_name("Data").data
  #     end.then do |data|
  #       async { expect(data.big_string).to eq("goodbygoodbygoodby") }
  #     end
  #   end
  # end
  #
  # async "is time to change the value completely and save it (no force needed)" do
  #   user = User.find_by_first_name("Data")
  #   user.data = TestData.new("the end", 1)
  #   user.save.then do
  #     Hyperstack::Component::IsomorphicHelpers.load_context
  #     ReactiveRecord.load do
  #       User.find_by_first_name("Data").data
  #     end.then do |data|
  #       async { expect(data.big_string).to eq("the end") }
  #     end
  #   end
  # end
  #
  # async "is time to delete the value and see if returns nil after saving" do
  #   user = User.find_by_first_name("Data")
  #   user.data = nil
  #   user.save.then do
  #     Hyperstack::Component::IsomorphicHelpers.load_context
  #     ReactiveRecord.load do
  #       User.find_by_first_name("Data").data
  #     end.then do |data|
  #       async { expect(data).to be_nil }
  #     end
  #   end
  # end
  #
  # it "is time to delete our user" do
  #   User.find_by_first_name("Data").destroy.then do
  #     expect(User.find_by_first_name("Data")).to be_destroyed
  #   end
  # end
  #
  # it "is time to see to make sure a nil aggregate that has never had a value returns nil" do
  #   ReactiveRecord.load do
  #     User.find_by_email("mitch@catprint.com").data
  #   end.then do |data|
  #     expect(data).to be_nil
  #   end
  # end

end
