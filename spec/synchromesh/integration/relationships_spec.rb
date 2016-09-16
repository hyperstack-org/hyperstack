require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "synchronizing relationships", js: true do

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
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end
  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
    end
    size_window(:small, :portrait)
  end

  it "belongs_to with associated record present" do
    parent = FactoryGirl.create(:test_model)
    mount "TestComponent2", model: parent do
      class TestComponent2 < React::Component::Base
        param :model, type: TestModel
        render(:div) do
          div { "#{model.child_models.count} items" }
          ul { model.child_models.each { |model| li { model.child_attribute }}}
        end
      end
    end
    page.should have_content("0 items")
    FactoryGirl.create(:child_model, test_model: parent, child_attribute: "first child")
    page.should have_content("1 items")
    parent.child_models << FactoryGirl.create(:child_model, child_attribute: "second child")
    page.should have_content("2 items")
    parent.child_models.first.destroy
    page.should have_content("1 items")
  end

  it "belongs_to without the associated record" do
    parent = FactoryGirl.create(:test_model)
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        render(:div) do
          div { "#{ChildModel.all.count} items" }
          ul { ChildModel.all.each { |model| li { model.child_attribute }}}
        end
      end
    end
    page.should have_content("0 items")
    FactoryGirl.create(:child_model, test_model: parent, child_attribute: "first child")
    page.should have_content("1 items")
    parent.child_models << FactoryGirl.create(:child_model, child_attribute: "second child")
    page.should have_content("2 items")
    parent.child_models.first.destroy
    page.should have_content("1 items")
  end

  it "composed_of"

end
