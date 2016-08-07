require 'spec_helper'
require 'synchromesh/test_components'

describe "scope enhancements", js: true, skip: "not working yet" do

  before(:all) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require 'pusher-fake/support/rspec'

    Synchromesh.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end
  end

  it "can have a hash in the scope" do
    isomorphic do
      TestModel.class_eval { scope :with_args, :no_client_sync, lambda { |opts| where(completed: true)}}
    end
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        render do
          "count = #{TestModel.with_args(true).count}"
        end
      end
    end
    page.should have_content('count = 0')
    FactoryGirl.create(:test_model, test_attribute: "model 1", completed: true)
    page.should have_content('count = 1')
    FactoryGirl.create(:test_model, test_attribute: "model 2", completed: false)
    FactoryGirl.create(:test_model, test_attribute: "model 3", completed: true)
    page.should have_content('count = 2')
  end
end
