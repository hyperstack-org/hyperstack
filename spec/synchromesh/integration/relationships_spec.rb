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
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it "belongs_to with count" do
    parent = FactoryGirl.create(:test_model)
    mount "TestComponent2", model: parent do
      class TestComponent2 < React::Component::Base
        param :model, type: TestModel
        render(:div) do
          puts "RENDERING! #{params.model.child_models.count} items"
          div { "#{params.model.child_models.count} items" }
          #ul { model.child_models.each { |model| li { model.child_attribute }}}
        end
      end
      ReactiveRecord::Collection.hypertrace instrument: :all
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
          div { "#{ChildModel.count} items" }
          ul { ChildModel.each { |model| li { model.child_attribute }}}
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

  it "adding child to a new model on client" do
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        before_mount do
          @parent = TestModel.new
        end
        after_mount do
          @parent.child_models << ChildModel.new
          @parent.save
        end
        render(:div) do
          "parent has #{@parent.child_models.count} children".tap { |s| puts s}
        end
      end
    end
    page.should have_content("parent has 1 children")
    expect(TestModel.first.child_models.count).to eq(1)
  end

  it "adding child to a new model on client after render" do
    # Synchromesh.configuration do |config|
    #   #config.transport = :none
    # end
    m = FactoryGirl.create(:test_model)
    m.child_models << FactoryGirl.create(:child_model)
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        def self.parent
          @parent ||= TestModel.find(1)
        end
        def self.add_child
          parent.child_models << ChildModel.new
          parent.save
        end
        render(:div) do
          "parent has #{TestComponent2.parent.child_models.count} children".tap { |s| puts s}
        end
      end
    end
    wait_for_ajax
    expect(TestModel.first.child_models.count).to eq(1)
    m.child_models << FactoryGirl.create(:child_model)
    evaluate_ruby("TestComponent2.add_child")
    page.should have_content("parent has 3 children")
  end

  it "will re-render the count after an item is added or removed from a model" do
    m1 = FactoryGirl.create(:test_model)
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        render(:div) do
          "Count of TestModel: #{TestModel.count}".span
        end
      end
    end
    page.should have_content("Count of TestModel: 1")
    m2 = FactoryGirl.create(:test_model)
    page.should have_content("Count of TestModel: 2")
    m1.destroy
    page.should have_content("Count of TestModel: 1")
    m2.destroy
    page.should have_content("Count of TestModel: 0")
  end

  it "will re-render the model's all scope after an item is added or removed" do
    m1 = FactoryGirl.create(:test_model)
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        render(:div) do
          puts "Count of TestModel: #{TestModel.collect { |i| i.id}.length}"
          "Count of TestModel: #{TestModel.collect { |i| i.id}.length}".span
        end
      end
    end
    page.should have_content("Count of TestModel: 1")
    m2 = FactoryGirl.create(:test_model)
    page.should have_content("Count of TestModel: 2")
    m1.destroy
    page.should have_content("Count of TestModel: 1")
    m2.destroy
    page.should have_content("Count of TestModel: 0")
  end

  it "composed_of"

end
