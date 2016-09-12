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
    on_client do
      # patch Synchromesh.connect so it doesn't execute until we say so
      # this is NOT used by the polling connection FYI
      module Synchromesh
        class << self
          alias old_connect connect
          def go_ahead_and_connect
            old_connect(*@connect_args)
          end
          def connect(*args)
            @connect_args = args
          end
        end
      end
    end
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
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq(['TestApplication'])
    end

    it "will not keep the temporary polled connection open" do
      mount "TestComponent"
      Synchromesh::Connection.active.should =~ ['TestApplication']
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq([])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq(['TestApplication'])
      ApplicationController.acting_user = true
      mount "TestComponent"
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.refresh_channels_every)
      wait_for { Synchromesh::Connection.active }.to eq([])
    end

    it "receives change notifications" do
      # one tricky thing about synchromesh is that we want to capture all
      # changes to the database that might be made while the client connections
      # is still being initialized.  To do this we establish a server side
      # queue of all messages sent between the time the page begins rendering
      # until the connection is established.

      # mount our test component
      mount "TestComponent"
      # add a model
      TestModel.new(test_attribute: "I'm new here!").save
      # until we connect there should only be 5 items
      page.should have_content("5 items")
      # okay now we can go ahead and connect (this runs on the client)
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      # once we connect it should change to 6
      page.should have_content("6 items")
      # now that we are connected the UI should keep updating
      TestModel.new(test_attribute: "I'm also new here!").save
      page.should have_content("7 items")
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      TestModel.first.destroy
      page.should have_content("5 items")
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
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
      Synchromesh::Connection.active.should =~ ['TestApplication']
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      wait_for_ajax
      ApplicationController.acting_user = true
      mount "TestComponent"
      Synchromesh::Connection.active.should =~ ['TestApplication']
      Timecop.travel(Time.now+Synchromesh.expire_polled_connection_in)
      wait(10.seconds).for { Synchromesh::Connection.active }.to eq([])
    end

    it "receives change notifications" do
      mount "TestComponent"
      TestModel.new(test_attribute: "I'm new here!").save
      Synchromesh::Connection.active.should =~ ['TestApplication']
      page.should have_content("6 items")
      Synchromesh::Connection.active.should =~ ['TestApplication']
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      TestModel.first.destroy
      page.should have_content("4 items")
    end

  end

  context "Real Pusher Account", skip: (pusher_credentials ? false : SKIP_MESSAGE) do

    before(:each) do
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
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq(['TestApplication'])
    end

    it "will not keep the temporary polled connection open" do
      mount "TestComponent"
      Synchromesh::Connection.active.should =~ ['TestApplication']
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq([])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq(['TestApplication'])
      ApplicationController.acting_user = true
      mount "TestComponent"
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.refresh_channels_every)
      wait_for { Synchromesh::Connection.active }.to eq([])
    end

    it "receives change notifications" do
      # one tricky thing about synchromesh is that we want to capture all
      # changes to the database that might be made while the client connections
      # is still being initialized.  To do this we establish a server side
      # queue of all messages sent between the time the page begins rendering
      # until the connection is established.

      # mount our test component
      mount "TestComponent"
      # add a model
      TestModel.new(test_attribute: "I'm new here!").save
      # until we connect there should only be 5 items
      page.should have_content("5 items")
      # okay now we can go ahead and connect (this runs on the client)
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      # once we connect it should change to 6
      page.should have_content("6 items")
      # now that we are connected the UI should keep updating
      TestModel.new(test_attribute: "I'm also new here!").save
      page.should have_content("7 items")
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      TestModel.first.destroy
      page.should have_content("5 items")
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      page.should have_content("4 items")
    end

  end

  context "Action Cable" do

    before(:each) do
      Synchromesh.configuration do |config|
        config.transport = :action_cable
        config.channel_prefix = "synchromesh"
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq(['TestApplication'])
    end

    it "will not keep the temporary polled connection open" do
      mount "TestComponent"
      Synchromesh::Connection.active.should =~ ['TestApplication']
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq([])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      Timecop.travel(Time.now+Synchromesh::Connection.transport.expire_new_connection_in)
      wait_for { Synchromesh::Connection.active }.to eq(['TestApplication'])
      ApplicationController.acting_user = true
      mount "TestComponent"
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      wait_for { Synchromesh::Connection.active }.to eq([])
    end

    it "receives change notifications" do
      # one tricky thing about synchromesh is that we want to capture all
      # changes to the database that might be made while the client connections
      # is still being initialized.  To do this we establish a server side
      # queue of all messages sent between the time the page begins rendering
      # until the connection is established.

      # mount our test component
      mount "TestComponent"
      # add a model
      TestModel.new(test_attribute: "I'm new here!").save
      # until we connect there should only be 5 items
      page.should have_content("5 items")
      # okay now we can go ahead and connect (this runs on the client)
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      # once we connect it should change to 6
      page.should have_content("6 items")
      # now that we are connected the UI should keep updating
      TestModel.new(test_attribute: "I'm also new here!").save
      page.should have_content("7 items")
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      TestModel.first.destroy
      page.should have_content("5 items")
      evaluate_ruby "Synchromesh.go_ahead_and_connect"
      page.should have_content("4 items")
    end

  end
end
