require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "default_scope" do

  context "client tests", js: true do

    before(:all) do
      require 'pusher'
      require 'pusher-fake'
      Pusher.app_id = "MY_TEST_ID"
      Pusher.key =    "MY_TEST_KEY"
      Pusher.secret = "MY_TEST_SECRET"
      require "pusher-fake/support/base"

      HyperMesh.configuration do |config|
        config.transport = :pusher
        config.channel_prefix = "synchromesh"
        config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
      end
    end

    before(:each) do
      # spec_helper resets the policy system after each test so we have to setup
      # before each test
      stub_const 'TestApplication', Class.new
      stub_const 'TestApplicationPolicy', Class.new
      TestApplicationPolicy.class_eval do
        always_allow_connection
        regulate_all_broadcasts { |policy| policy.send_all }
        allow_change(to: :all, on: [:create, :update, :destroy]) { true }
      end
      size_window(:small, :portrait)
    end

    after(:each) do
      TestModel.default_scopes = []
    end

    it "a default scope can be added server side using either a block or proc" do
      isomorphic do
        TestModel.class_eval do
          default_scope -> { where(completed: true) }
          default_scope { where(test_attribute: 'foo') }
        end
      end
      mount "TestComponent2" do
        class TestComponent2 < React::Component::Base
          render(:div) do
            "#{TestModel.count} items".br
            "#{TestModel.unscoped.count} unscoped items"
          end
        end
      end
      page.should have_content("0 items")
      page.should have_content("0 unscoped items")
      m1 = FactoryGirl.create(:test_model, completed: false, test_attribute: nil)
      page.should have_content("0 items")
      page.should have_content("1 unscoped items")
      m2 = FactoryGirl.create(:test_model, completed: true, test_attribute: nil)
      page.should have_content("0 items")
      page.should have_content("2 unscoped items")
      m2.update(test_attribute: 'foo')
      page.should have_content("1 items")
      page.should have_content("2 unscoped items")
      m3 = FactoryGirl.create(:test_model)
      page.should have_content("2 items")
      page.should have_content("3 unscoped items")
      m3.update_attribute(:completed, false)
      page.should have_content("1 items")
      page.should have_content("3 unscoped items")
      m2.destroy
      page.should have_content("0 items")
      page.should have_content("2 unscoped items")
    end

    it "a default scope can be added client side" do
      isomorphic do
        TestModel.class_eval do
          default_scope server: -> { where(completed: true) },
                        client: -> { completed }
          default_scope server: -> { where(test_attribute: 'foo') },
                        client: -> { test_attribute == 'foo' }
        end
      end
      mount "TestComponent2" do
        class TestComponent2 < React::Component::Base
          render(:div) do
            "#{TestModel.count} items".br
            "#{TestModel.unscoped.count} unscoped items"
          end
        end
      end
      starting_fetch_time = evaluate_ruby("ReactiveRecord::Base.last_fetch_at")
      page.should have_content("0 items")
      page.should have_content("0 unscoped items")
      m1 = FactoryGirl.create(:test_model, completed: false, test_attribute: nil)
      page.should have_content("0 items")
      page.should have_content("1 unscoped items")
      m2 = FactoryGirl.create(:test_model, completed: true, test_attribute: nil)
      page.should have_content("0 items")
      page.should have_content("2 unscoped items")
      m2.update(test_attribute: 'foo')
      page.should have_content("1 items")
      page.should have_content("2 unscoped items")
      m3 = FactoryGirl.create(:test_model)
      page.should have_content("2 items")
      page.should have_content("3 unscoped items")
      m3.update_attribute(:completed, false)
      page.should have_content("1 items")
      page.should have_content("3 unscoped items")
      m2.destroy
      page.should have_content("0 items")
      page.should have_content("2 unscoped items")
      # there should be no client fetches should replace this with a double of
      # ServerDataCache[] which should not be called
      wait_for_ajax
      starting_fetch_time.should eq(evaluate_ruby("ReactiveRecord::Base.last_fetch_at"))
    end
  end
end
