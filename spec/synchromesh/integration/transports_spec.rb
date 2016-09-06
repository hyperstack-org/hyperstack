require 'spec_helper'
require 'synchromesh/integration/test_components'

SKIP_MESSAGE = 'Pusher credentials not specified. '\
 'To run set env variable PUSHER=xxxx-yyy-zzz (app id - key - secret)'

def pusher_credentials
  Hash[*[:app_id, :key, :secret].zip(ENV['PUSHER'].split('-')).flatten]
rescue
  nil
end

describe "Transport Tests", js: true do

  before(:each) do
    5.times { |i| FactoryGirl.create(:test_model, test_attribute: "I am item #{i}") }
  end

  before(:each) do
    ApplicationController.acting_user = nil
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      regulate_class_connection { !self }
      regulate_all_broadcasts { |policy| policy.send_all }
    end
    size_window(:small, :portrait)
    File.delete('synchromesh-simple-poller-store') if File.exists? 'synchromesh-simple-poller-store'
    File.delete(Synchromesh::PusherChannels::STORE_ID) if File.exists? Synchromesh::PusherChannels::STORE_ID
  end

  after(:each) do
    Timecop.return
    wait_for_ajax
  end

  context "Pusher-Fake" do
    before(:all) do

      require 'pusher'
      require 'pusher-fake'
      Pusher.app_id = "MY_TEST_ID"
      Pusher.key =    "MY_TEST_KEY"
      Pusher.secret = "MY_TEST_SECRET"
      require "pusher-fake/support/base"

      Synchromesh.configuration do |config|
        config.transport = :pusher
        config.channel_prefix = "synchromesh"
        config.opts = {
          app_id: Pusher.app_id,
          key: Pusher.key,
          secret: Pusher.secret,
          auth: {headers: {'X-CSRF-Token': "123"}},
          authEndpoint: "rr/synchromesh-pusher-auth"
        }.merge(PusherFake.configuration.web_options)
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
      ApplicationController.acting_user = true
      mount "TestComponent"
      Timecop.travel(Time.now+Synchromesh::PusherChannels::POLL_INTERVAL)
      wait_for { Synchromesh.open_connections.to_a }.to eq([])
    end

    it "receives change notifications" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
      TestModel.new(test_attribute: "I'm new here!").save
      page.should have_content("6 items")
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
      TestModel.first.destroy
      page.should have_content("4 items")
    end
  end

  context "Simple Polling" do

    before(:all) do
      Synchromesh.configuration do |config|
        config.transport = :simple_poller
        # slow down the polling so wait_for_ajax works
        config.opts = { seconds_between_poll: 2 }
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      Synchromesh.open_connections.should =~ ['TestApplication']
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      wait_for_ajax
      ApplicationController.acting_user = true
      mount "TestComponent"
      Synchromesh.open_connections.should =~ ['TestApplication']
      Timecop.travel(Time.now+Synchromesh.seconds_polled_data_will_be_retained)
      wait(10.seconds).for { Synchromesh.open_connections }.to eq([])
    end

    it "receives change notifications" do
      mount "TestComponent"
      TestModel.new(test_attribute: "I'm new here!").save
      Synchromesh.open_connections.should =~ ['TestApplication']
      page.should have_content("6 items")
      Synchromesh.open_connections.should =~ ['TestApplication']
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      TestModel.first.destroy
      page.should have_content("4 items")
    end

  end

  context "Real Pusher Account", skip: (pusher_credentials ? false : SKIP_MESSAGE) do

    before(:all) do
      require 'pusher'
      Object.send(:remove_const, :PusherFake) if defined?(PusherFake)

      Synchromesh.configuration do |config|
        config.transport = :pusher
        config.channel_prefix = "synchromesh"
        config.opts = pusher_credentials
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
      ApplicationController.acting_user = true
      mount "TestComponent"
      Timecop.travel(Time.now+Synchromesh::PusherChannels::POLL_INTERVAL)
      wait_for { Synchromesh.open_connections.to_a }.to eq([])
    end

    it "receives change notifications" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
      TestModel.new(test_attribute: "I'm new here!").save
      page.should have_content("6 items")
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      wait_for { Synchromesh.open_connections.to_a }.to eq(['TestApplication'])
      TestModel.first.destroy
      page.should have_content("4 items")
    end

  end
end
