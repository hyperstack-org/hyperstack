require 'spec_helper'
require 'test_components'

describe "authorization integration", js: true do

  before(:all) do
    # Hyperloop.configuration do |config|
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

    Hyperloop.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end

  end

  after(:all) do
    ApplicationController.acting_user = nil
    ActiveRecord::Base.class_eval do
      def create_permitted?
        true
      end
      def update_permitted?
        true
      end
      def destroy_permitted?
        true
      end
      def view_permitted?(attribute)
        true
      end
    end
  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    User
    stub_const "User", Class.new
    User.class_eval do
      include ActiveModel::Model
      attr_accessor :name
    end
    ApplicationController.acting_user = nil
    stub_const 'TestApplicationPolicy', Class.new
    stub_const 'TestApplication', Class.new
    TestApplicationPolicy.class_eval do
      regulate_class_connection { self }
      regulate_instance_connections(TestModel) { TestModel.find_by_test_attribute(name) }
      regulate_all_broadcasts { |policy| policy.send_all_but(:completed, :test_attribute)}
      regulate_broadcast(TestModel) { |policy| policy.send_all_but(:created_at).to(self) }
    end
    size_window(:small, :portrait)
  end

  it 'will not allow access to attributes through a collection' do
    client_option raise_on_js_errors: :off
    FactoryBot.create(:test_model, test_attribute: 'hello', completed: false)
    FactoryBot.create(:test_model, test_attribute: 'goodby', completed: true)
    mount 'TestComponent2' do
      module ReactiveRecord
        class Base
          class << self
            attr_accessor :last_log_message
            def log(*args)
              Base.last_log_message = args
            end
          end
        end
      end
    end
    wait_for_ajax
    ApplicationController.acting_user = User.new(name: 'fred')
    page.evaluate_ruby('Hyperloop.connect("TestApplication")')
    evaluate_ruby do
      TestModel.all[0].test_attribute
    end
    wait_for_ajax
    expect_evaluate_ruby('ReactiveRecord::Base.last_log_message').to eq(['Fetch failed', 'error'])
  end

  it 'will only return authorized attributes on creation' do
    client_option raise_on_js_errors: :off
    TestModel.class_eval do
      def create_permitted?
        true
      end
    end
    mount 'TestComponent2'
    wait_for_ajax
    ApplicationController.acting_user = User.new(name: 'fred')
    page.evaluate_ruby('Hyperloop.connect("TestApplication")')
    TestModel.before_save { self.test_attribute ||= 'top secret' }
    expect_promise do
      model = TestModel.new(updated_at: 12)
      model.save.then do
        model.attributes.keys
      end
    end.to contain_exactly("id", "created_at", "updated_at", "child_models")
  end

  it "will only synchronize the connected channels" do
    mount "TestComponent2"
    model1 = FactoryBot.create(:test_model, test_attribute: "hello")
    wait_for_ajax
    model1.attributes_on_client(page).should eq({id: 1})
    ApplicationController.acting_user = User.new(name: "fred")
    page.evaluate_ruby('Hyperloop.connect("TestApplication")')
    wait_for_ajax
    # sleep a little, to make sure that on fast systems the seconds precision is covered
    sleep 2
    model1.update_attribute(:test_attribute, 'george')
    wait_for_ajax
    # make sure the order of the elements in the returned hash does not fail the test
    # make sure time zone doesn't matter, as it is about time in space
    # we get only seconds precision, millisecs are dropped in AR adapters here, but they are in the db with pg
    # compare only with seconds precision
    m1_attr_cl1 = model1.attributes_on_client(page)
    m1_attr_cl1[:id].should eq(1)
    m1_attr_cl1[:created_at].to_time.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z').should eq(model1.created_at.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z'))
    m1_attr_cl1[:updated_at].to_time.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z').should eq(model1.updated_at.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z'))
    ApplicationController.acting_user = User.new(name: "george")
    page.evaluate_ruby("Hyperloop.connect(['TestModel', #{model1.id}])")
    wait_for_ajax
    sleep 2
    model1.update_attribute(:completed, true)
    wait_for_ajax
    m1_attr_cl2 = model1.attributes_on_client(page)
    m1_attr_cl2[:id].should eq(1)
    m1_attr_cl2[:test_attribute].should eq("george")
    m1_attr_cl2[:completed].should eq(true)
    m1_attr_cl2[:created_at].to_time.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z').should eq(model1.created_at.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z'))
    m1_attr_cl2[:updated_at].to_time.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z').should eq(model1.updated_at.localtime(0).strftime('%Y-%m-%dT%H:%M:%S%z'))
  end

  it "will fail on illegal class connections" do
    client_option raise_on_js_errors: :off
    mount "TestComponent2"
    model1 = FactoryBot.create(:test_model, test_attribute: "hello")
    page.evaluate_ruby('Hyperloop.connect("TestApplication")')
    model1.update_attribute(:test_attribute, 'george')
    wait_for_ajax
    model1.attributes_on_client(page).should eq({id: 1})
  end

  it "will fail on illegal instance connections" do
    client_option raise_on_js_errors: :off
    mount "TestComponent2"
    model1 = FactoryBot.create(:test_model, test_attribute: "george")
    ApplicationController.acting_user = User.new(name: "fred")
    page.evaluate_ruby("Hyperloop.connect(['TestModel', #{model1.id}])")
    model1.update_attribute(:completed, true)
    wait_for_ajax
    model1.attributes_on_client(page).should eq({id: 1})
  end

end
