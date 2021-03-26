require 'spec_helper'
require 'rspec-steps'

RSpec::Steps.steps 'Reading and Writing Enums', js: true do

  before(:each) do

    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperstack.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret, use_tls: false}.merge(PusherFake.configuration.web_options)
    end
  end
  before(:step) do
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
    end
    ApplicationController.acting_user = nil
  end

  it "can change the enum and read it back" do
    User.create(name: 'test user')
    evaluate_ruby do
      ReactiveRecord.load { User.find(1).itself }.then do |user|
        user.test_enum = :no
        user.save.then do
          Hyperstack::Component::IsomorphicHelpers.load_context
          ReactiveRecord.load do
            User.find(1).test_enum
         end
       end
      end
    end.to eq('no')
  end

  # async "can set it back" do
  #   Hyperstack::Component::IsomorphicHelpers.load_context
  #   set_acting_user "super-user"
  #   user = User.find(1)
  #   user.test_enum = :yes
  #   user.save.then do
  #     Hyperstack::Component::IsomorphicHelpers.load_context
  #     ReactiveRecord.load do
  #       User.find(1).test_enum
  #     end.then do |test_enum|
  #       async { expect(test_enum).to eq(:yes) }
  #     end
  #   end
  # end
  #
  # it "can change it back" do
  #   user = User.find(1)
  #   user.test_enum = :yes
  #   user.save.then do |success|
  #     expect(success).to be_truthy
  #   end
  # end

end
