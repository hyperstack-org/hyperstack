require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "authorization integration", js: true do

  before(:all) do
    # Synchromesh.configuration do |config|
    #   config.transport = :simple_poller
    #   # slow down the polling so wait_for_ajax works
    #   config.opts = { seconds_between_poll: 2 }
    # end
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Synchromesh.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end

  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const "User", Class.new
    User.class_eval do
      include ActiveModel::Model
      attr_accessor :name
    end
    ApplicationController.acting_user = nil
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      regulate_class_connection { self }
      regulate_instance_connections(TestModel) { TestModel.find_by_test_attribute(name) }
      regulate_all_broadcasts { |policy| policy.send_all_but(:completed, :test_attribute) }
      regulate_broadcast(TestModel) { |policy| policy.send_all_but(:created_at).to(self) }
    end
  end

  it "will only synchronize the connected channels" do
    mount "TestComponent2"
    model1 = FactoryGirl.create(:test_model, test_attribute: "hello")
    wait_for_ajax
    model1.attributes_on_client(page).should eq({id: 1})
    ApplicationController.acting_user = User.new(name: "fred")
    page.evaluate_ruby('Synchromesh.connect("TestApplication")')
    puts "connected to TestApplication"
    wait_for_ajax
    model1.update_attribute(:test_attribute, 'george')
    puts "updated test_attribute = 'george'"
    wait_for_ajax
    sleep 5.seconds
    model1.attributes_on_client(page).should eq({
      id: 1,
      created_at: model1.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
      updated_at: model1.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
    })
    ApplicationController.acting_user = User.new(name: "george")
    page.evaluate_ruby("Synchromesh.connect(['TestModel', #{model1.id}])")
    wait_for_ajax
    sleep 5.seconds
    puts "should be connected to model"
    model1.update_attribute(:completed, true)
    sleep 5.seconds
    puts "lets get the data"
    wait_for_ajax
    model1.attributes_on_client(page).should eq({
      id: 1, test_attribute: "george", completed: true,
      created_at: model1.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
      updated_at: model1.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
    })
  end

  it "will fail on illegal class connections" do
    mount "TestComponent2"
    model1 = FactoryGirl.create(:test_model, test_attribute: "hello")
    page.evaluate_ruby('Synchromesh.connect("TestApplication")')
    model1.update_attribute(:test_attribute, 'george')
    wait_for_ajax
    model1.attributes_on_client(page).should eq({id: 1})
  end

  it "will fail on illegal instance connections" do
    mount "TestComponent2"
    model1 = FactoryGirl.create(:test_model, test_attribute: "george")
    ApplicationController.acting_user = User.new(name: "fred")
    page.evaluate_ruby("Synchromesh.connect(['TestModel', #{model1.id}])")
    model1.update_attribute(:completed, true)
    wait_for_ajax
    model1.attributes_on_client(page).should eq({id: 1})
  end

end
