require 'spec_helper'
require 'rspec-steps'

RSpec::Steps.steps 'alias_attribute', js: true do

  before(:each) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperloop.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
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
      class SubUser < User
      end
    end
    on_client do
      # Aliases are implemented as method aliases.  However these will not
      # work with class methods like create, so we also keep a hash of aliases
      # associated with the class.
      # In order to test alias inheritence we will just add this alias on the
      # client.  Thus if during any access we DID not inherit the alias
      # it will remain as client_name, which will break the server side store
      User.alias_attribute :client_name, :last_name
    end
  end

  it "implements find_by" do
    @user = User.create(first_name: "Mitch", last_name: "VanDuyn")
    expect_promise do
      ReactiveRecord.load { User.find_by(first_name: "Mitch", surname: "VanDuyn").id }
    end.to eq(@user.id)
  end

  it "implements the finder" do
    @user = User.create(first_name: "M.", last_name: "Pantel")
    expect_promise do
      ReactiveRecord.load { User.find_by_surname('Pantel').id }
    end.to eq(@user.id)
  end

  it "works with find_by without fetching from the DB" do
    expect_evaluate_ruby do
      User.find_by(first_name: 'M.', last_name: 'Pantel').id
    end.to eq(@user.id)
  end

  it "implements the getter" do
    expect_promise do
      ReactiveRecord.load { User.find_by_first_name('M.').surname }
    end.to eq('Pantel')
  end

  it "implements the setter" do
    evaluate_promise do
      user = User.find_by_first_name('M.')
      user.surname = "Someoneelse"
      user.save
    end
    expect(@user.reload.surname).to eq('Someoneelse')
  end

  it "implements the _changed? method" do
    expect_evaluate_ruby do
      user = User.find_by_first_name('M.')
      user.last_name = "Pantel"
      user.surname_changed?
    end.to be_truthy
  end

  it "can inherit the aliases" do
    evaluate_promise do
      SubUser.create(client_name: 'Fred')
    end
    expect(SubUser.find_by_surname('Fred')).to be_truthy
  end

end
