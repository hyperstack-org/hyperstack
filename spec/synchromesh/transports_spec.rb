require 'spec_helper'

describe "Transport Tests", js: true do

  before(:each) do
    5.times { |i| FactoryGirl.create(:test_model, test_attribute: "I am item #{i}") }

    on_client do
      class TestComponent < React::Component::Base
        render(:div) do
          div { "#{TestModel.all.count} items" }
          ul { TestModel.all.each { |model| li { model.test_attribute }}}
        end
      end
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

    it "receives change notifications" do
      mount "TestComponent"
      TestModel.new(test_attribute: "I'm new here!").save
      page.should have_content("6 items")
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      TestModel.first.destroy
      page.should have_content("4 items")
    end

  end

  context "Real Pusher Account" do

    before(:all) do
      require 'pusher'

      Object.send(:remove_const, :PusherFake) if defined?(PusherFake)

      Synchromesh.configuration do |config|
        config.transport = :pusher
        config.channel_prefix = "synchromesh"
        config.opts = {app_id: '231029', key: 'cfd95af0404b4d8a0dc7', secret: 'b91650d692c606e33818'}
      end
    end

    it "receives change notifications" do
      mount "TestComponent"
      TestModel.new(test_attribute: "I'm new here!").save
      page.should have_content("6 items")
    end

    it "receives destroy notifications" do
      mount "TestComponent"
      TestModel.first.destroy
      page.should have_content("4 items")
    end

  end
end
