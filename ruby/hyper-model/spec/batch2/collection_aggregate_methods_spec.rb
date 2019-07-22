require 'spec_helper'
require 'test_components'
require 'rspec-steps'

RSpec::Steps.steps "collection aggregate methods", js: true do

  before(:all) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperstack.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end
  end

  before(:step) do
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

  [:count, :empty?, :any?].each do |method|
    it "will not retrieve the entire collection when using #{method}" do
      FactoryBot.create(:test_model)

      expect_promise(<<-RUBY
        Hyperstack::Model
        .load { TestModel.#{method} }
        .then do |val|
          if TestModel.all.instance_variable_get('@collection')
            "unnecessary fetch of all"
          else
            val
          end
        end
      RUBY
    ).to eq(TestModel.all.send(method))
    end
  end

  it 'will retrieve the entire collection when using any? if an arg is passed in' do
    FactoryBot.create(:test_model)

    expect_promise(
      <<~RUBY
        Hyperstack::Model.load do
          TestModel.any?(TestModel)
        end.then do |val|
          if TestModel.all.instance_variable_get('@collection')
            'necessary fetch of all'
          else
            val
          end
        end
      RUBY
    ).to eq('necessary fetch of all')
  end

  it 'will retrieve the entire collection when using any? if a block is passed in' do
    FactoryBot.create(:test_model)

    expect_promise(
      <<~RUBY
        Hyperstack::Model.load do
          TestModel.any? { |test_model| test_model }
        end.then do |val|
          if TestModel.all.instance_variable_get('@collection')
            'necessary fetch of all'
          else
            val
          end
        end
      RUBY
    ).to eq('necessary fetch of all')
  end
end
