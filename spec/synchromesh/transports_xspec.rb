require 'spec_helper'

describe "Syncromesh", js: true do

  # make sure to turn off main spec before running these... and they can only be run one at a time...

  it "will notify the client when models change (using polling)" do

    Synchromesh.configuration do |config|
      config.transport = :simple_poller
      # slow down the polling so wait_for_ajax works
      config.opts = { seconds_between_poll: 2 }
    end

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


  it "will notify the client when models change (using real pusher account)" do

    require 'pusher'

    Synchromesh.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: '231029', key: 'cfd95af0404b4d8a0dc7', secret: "b91650d692c606e33818"}
    end

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
end
