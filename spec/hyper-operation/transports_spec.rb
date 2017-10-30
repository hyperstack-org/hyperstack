require 'spec_helper'

SKIP_MESSAGE = 'Pusher credentials not specified. '\
 'To run set env variable PUSHER=xxxx-yyy-zzz (app id - key - secret)'

def pusher_credentials
  Hash[*[:app_id, :key, :secret].zip(ENV['PUSHER'].split('-')).flatten]
rescue
  nil
end

describe "Transport Tests", js: true do

  before(:each) do
    stub_const "CreateTestModel", Class.new(Hyperloop::ServerOp)
    stub_const "MyControllerOp", Class.new(Hyperloop::ControllerOp)
    isomorphic do
      class MyControllerOp < Hyperloop::ControllerOp
        param :data
        dispatch_to { session_channel }
      end
      class CreateTestModel < Hyperloop::ServerOp
        param :test_attribute
      end
    end
    on_client do
      class TestComponent < React::Component::Base
        before_mount do
          state.items! []
          CreateTestModel.on_dispatch { |params| state.items! << params.test_attribute }
          MyControllerOp.on_dispatch { |params| mutate.message params.data }
        end
        render(:div) do
          div { "#{state.items.count} items" }
          ul { state.items.each { |test_attribute| li { test_attribute }}}
          div { state.message }
        end
      end
    end
  end

  before(:each) do
    ApplicationController.acting_user = nil
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    #stub_const 'ScopeIt', Class.new
    stub_const 'ScopeIt::TestApplicationPolicy', Class.new
    ScopeIt::TestApplicationPolicy.class_eval do
      regulate_class_connection { !self }
      always_dispatch_from(CreateTestModel)
    end
    size_window(:small, :portrait)
    on_client do
      # patch Hyperloop.connect so it doesn't execute until we say so
      # this is NOT used by the polling connection FYI
      module Hyperloop
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

      Hyperloop.configuration do |config|
        config.connect_session = false
        config.transport = :pusher
        config.opts = {
          app_id: Pusher.app_id,
          key: Pusher.key,
          secret: Pusher.secret
        }.merge(PusherFake.configuration.web_options)
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq(['ScopeIt::TestApplication'])
    end

    it "will not keep the temporary polled connection open" do
      mount "TestComponent"
      Hyperloop::Connection.active.should =~ ['ScopeIt::TestApplication']
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq([])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq(['ScopeIt::TestApplication'])
      ApplicationController.acting_user = true
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.refresh_channels_every)
      wait_for { Hyperloop::Connection.active }.to eq([])
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
      CreateTestModel.run(test_attribute: "I'm new here!")
      # until we connect there should only be 5 items
      page.should have_content("0 items")
      # okay now we can go ahead and connect (this runs on the client)
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      # once we connect it should change to 6
      page.should have_content("1 items")
      # now that we are connected the UI should keep updating
      CreateTestModel.run(test_attribute: "I'm also new here!")
      page.should have_content("2 items")
    end

    it "broadcasts to the session channel" do
      Hyperloop.connect_session = true
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      wait_for_ajax
      evaluate_ruby "MyControllerOp.run(data: 'hello')"
      page.should have_content("hello")
    end
  end

  context "Simple Polling" do

    before(:all) do
      Hyperloop.configuration do |config|
        config.connect_session = false
        config.transport = :simple_poller
        # slow down the polling so wait_for_ajax works
        config.opts = { seconds_between_poll: 2 }
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      Hyperloop::Connection.active.should =~ ['ScopeIt::TestApplication']
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      wait_for_ajax
      ApplicationController.acting_user = true
      mount "TestComponent"
      Hyperloop::Connection.active.should =~ ['ScopeIt::TestApplication']
      Timecop.travel(Time.now+Hyperloop.expire_polled_connection_in)
      wait(10.seconds).for { Hyperloop::Connection.active }.to eq([])
    end

    it "receives change notifications" do
      mount "TestComponent"
      CreateTestModel.run(test_attribute: "I'm new here!")
      Hyperloop::Connection.active.should =~ ['ScopeIt::TestApplication']
      page.should have_content("1 items")
      Hyperloop::Connection.active.should =~ ['ScopeIt::TestApplication']
    end

    it "broadcasts to the session channel" do
      Hyperloop.connect_session = true
      mount "TestComponent"
      sleep 0.25
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      wait_for_ajax
      evaluate_ruby "MyControllerOp.run(data: 'hello')"
      page.should have_content("hello")
    end

  end

  context "Real Pusher Account", skip: (pusher_credentials ? false : SKIP_MESSAGE) do

    before(:each) do
      require 'pusher'
      Object.send(:remove_const, :PusherFake) if defined?(PusherFake)

      Hyperloop.configuration do |config|
        config.connect_session = false
        config.transport = :pusher
        config.opts = pusher_credentials
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq(['ScopeIt::TestApplication'])
    end

    it "will not keep the temporary polled connection open" do
      mount "TestComponent"
      Hyperloop::Connection.active.should =~ ['ScopeIt::TestApplication']
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq([])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq(['ScopeIt::TestApplication'])
      ApplicationController.acting_user = true
      sleep 1 # needed so Pusher can catch up since its not controlled by timecop
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.refresh_channels_every)
      wait_for { Hyperloop::Connection.active }.to eq([])
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
      CreateTestModel.run(test_attribute: "I'm new here!")
      # until we connect there should only be 5 items
      page.should have_content("0 items")
      # okay now we can go ahead and connect (this runs on the client)
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      # once we connect it should change to 6
      page.should have_content("1 items")
      # now that we are connected the UI should keep updating
      CreateTestModel.run(test_attribute: "I'm also new here!")
      page.should have_content("2 items")
    end

    it "broadcasts to the session channel" do
      Hyperloop.connect_session = true
      mount "TestComponent"
      sleep 0.25
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      wait_for_ajax
      evaluate_ruby "MyControllerOp.run(data: 'hello')"
      page.should have_content("hello")
    end
  end

  context "Action Cable" do

    before(:each) do
      Hyperloop.configuration do |config|
        config.connect_session = false
        config.transport = :action_cable
        config.channel_prefix = "synchromesh"
      end
    end

    it "opens the connection" do
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq(['ScopeIt::TestApplication'])
    end

    it "will not keep the temporary polled connection open" do
      mount "TestComponent"
      Hyperloop::Connection.active.should =~ ['ScopeIt::TestApplication']
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq([])
    end

    it "sees the connection going offline" do
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      Timecop.travel(Time.now+Hyperloop::Connection.transport.expire_new_connection_in)
      wait_for { Hyperloop::Connection.active }.to eq(['ScopeIt::TestApplication'])
      ApplicationController.acting_user = true
      mount "TestComponent"
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      wait_for { Hyperloop::Connection.active }.to eq([])
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
      CreateTestModel.run(test_attribute: "I'm new here!")
      # until we connect there should only be 5 items
      page.should have_content("0 items")
      # okay now we can go ahead and connect (this runs on the client)
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      # once we connect it should change to 6
      page.should have_content("1 items")
      # now that we are connected the UI should keep updating
      CreateTestModel.run(test_attribute: "I'm also new here!")
      page.should have_content("2 items")
    end

    it "broadcasts to the session channel" do
      Hyperloop.connect_session = true
      mount "TestComponent"
      sleep 0.25
      evaluate_ruby "Hyperloop.go_ahead_and_connect"
      wait_for_ajax
      evaluate_ruby "MyControllerOp.run(data: 'hello')"
      page.should have_content("hello")
    end
  end
end
