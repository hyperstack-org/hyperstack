require 'spec_helper'
require 'rspec-steps'

RSpec::Steps.steps 'the where method and class delegation', js: true do

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
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret, use_tls: false}.merge(PusherFake.configuration.web_options)
    end
  end

  before(:step) do
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    ApplicationController.acting_user = nil
    isomorphic do
      User.alias_attribute :surname, :last_name
      User.class_eval do
        def self.with_size(attr, size)
          where("LENGTH(#{attr}) = ?", size)
        end
      end
    end

    @user1 = User.create(first_name: "Mitch", last_name: "VanDuyn")
    User.create(first_name: "Joe", last_name: "Blow")
    @user2 = User.create(first_name: "Jan", last_name: "VanDuyn")
    User.create(first_name: "Ralph", last_name: "HooBo")
  end

  it "can take a hash like value" do
    expect do
      ReactiveRecord.load { User.where(surname: "VanDuyn").pluck(:id, :first_name) }
    end.on_client_to eq User.where(surname: "VanDuyn").pluck(:id, :first_name)
  end

  it "and will update the collection on the client " do
    User.create(first_name: "Paul", last_name: "VanDuyn")
    expect do
      User.where(surname: "VanDuyn").pluck(:id, :first_name)
    end.on_client_to eq User.where(surname: "VanDuyn").pluck(:id, :first_name)
  end

  it "or it can take SQL plus params" do
    expect do
      Hyperstack::Model.load { User.where("first_name LIKE ?", "J%").pluck(:first_name, :surname) }
    end.on_client_to eq User.where("first_name LIKE ?", "J%").pluck(:first_name, :surname)
  end

  it "class methods will be called from collections" do
    expect do
      Hyperstack::Model.load { User.where(last_name: 'VanDuyn').with_size(:first_name, 3).pluck('first_name') }
    end.on_client_to eq User.where(last_name: 'VanDuyn').with_size(:first_name, 3).pluck('first_name')
  end

  it "where-s can be chained (cause they are just class level methods after all)" do
    expect do
      Hyperstack::Model.load { User.where(last_name: 'VanDuyn').where(first_name: 'Jan').pluck(:id) }
    end.on_client_to eq User.where(last_name: 'VanDuyn', first_name: 'Jan').pluck(:id)
  end

end
