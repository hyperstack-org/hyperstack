require 'spec_helper'

describe "Syncromesh", js: true do

  require 'pusher'
  require 'pusher-fake'
  Pusher.app_id = "MY_TEST_ID"
  Pusher.key = "MY_TEST_KEY"
  Pusher.secret = "MY_TEST_SECRET"
  require 'pusher-fake/support/rspec'

  Synchromesh.configuration do |config|
    config.transport = :pusher
    config.channel_prefix = "synchromesh"
    config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
  end

  it "synchronize on update" do

    test_model = FactoryGirl.create(:test_model, test_attribute: "hello")

    mount "TestComponent", test_model: test_model do
      class TestComponent < React::Component::Base
        param :test_model, type: TestModel
        render { params.test_model.test_attribute }
      end
    end

    page.should have_content("hello")
    test_model.test_attribute = "goodby"
    test_model.save
    page.should have_content("goodby")

  end

  describe ".all" do
    before(:each) do
      5.times { |i| FactoryGirl.create(:test_model, test_attribute: "I am item #{i}") }

      mount "TestComponent" do
        class TestComponent < React::Component::Base
          render(:div) do
            div { "#{TestModel.all.count} items" }
            ul { TestModel.all.each { |model| li { model.test_attribute }}}
          end
        end
      end
      page.should have_content("5 items")
    end

    it "will synchronize on create" do
      TestModel.new(test_attribute: "I'm new here!").save
      page.should have_content("6 items")
    end

    it "will synchronize on destroy" do
      TestModel.first.destroy
      page.should have_content("4 items")
    end
  end

  describe "scopes" do
    before(:each) do
      5.times { |i| FactoryGirl.create(:test_model, test_attribute: "I am item #{i}", completed: false) }

      mount "TestComponent" do
        class TestComponent < React::Component::Base
          render(:div) do
            div { "#{TestModel.active.count} items" }
            ul { TestModel.active.each { |model| li { model.test_attribute }}}
          end
        end
      end
      page.should have_content("5 items")
    end

    it "will synchronize on create" do
      TestModel.new(test_attribute: "I'm new here!", completed: false).save
      page.should have_content("6 items")
    end

    it "will synchronize on destroy" do
      TestModel.first.destroy
      page.should have_content("4 items")
    end

    it "will syncronize on an attribute change" do
      # TestModel.first.tap do |model|
      #   model.completed = true
      #   model.save
      # end
      TestModel.first.update_attribute(:completed, true)
      page.should have_content("4 items")
    end
  end
end
