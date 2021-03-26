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
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret, use_tls: false}.merge(PusherFake.configuration.web_options)
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

  %i[count empty? any? none?].each do |method|
    it "will not retrieve the entire collection when using #{method}" do
      FactoryBot.create(:test_model)

      expect do
        Hyperstack::Model
        .load { TestModel.send(method) }
        .then do |val|
          if TestModel.all.instance_variable_get('@collection')
            "unnecessary fetch of all"
          else
            val
          end
        end
      end.on_client_to eq(TestModel.all.send(method))
    end
  end

  %i[any? none?].each do |method|
    it "will retrieve the entire collection when using #{method} if an arg is passed in" do
      FactoryBot.create(:test_model)

      expect do
        Hyperstack::Model.load do
          TestModel.send(method, TestModel)
        end.then do |val|
          if TestModel.all.instance_variable_get('@collection')
            'necessary fetch of all'
          else
            val
          end
        end
      end.on_client_to eq('necessary fetch of all')
    end unless Opal::VERSION.split('.')[0..1] == ['0', '11']  # opal 0.11 didn't support a value passed to any

    it 'will retrieve the entire collection when using any? if a block is passed in' do
      FactoryBot.create(:test_model)

      expect do
        Hyperstack::Model.load do
          TestModel.send(method) { |test_model| test_model }
        end.then do |val|
          if TestModel.all.instance_variable_get('@collection')
            'necessary fetch of all'
          else
            val
          end
        end
      end.on_client_to eq('necessary fetch of all')
    end
  end
end
