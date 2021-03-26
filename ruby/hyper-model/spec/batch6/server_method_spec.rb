require 'spec_helper'
require 'rspec-steps'

RSpec::Steps.steps 'server_method', js: true do

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

    #User.do_not_synchronize
  end

  before(:step) do
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    ApplicationController.acting_user = nil
  end

  it "can call a server method" do
    isomorphic do
      TodoItem.class_eval do
        class << self
          attr_writer :server_method_count

          def server_method_count
            @server_method_count ||= 0
          end
        end
        server_method(:test, default: 0) { TodoItem.server_method_count += 1 }
      end
      TestModel.server_method(:test) { child_models.count }
    end
    TodoItem.create
    mount 'ServerMethodTester' do
      class ServerMethodTester < HyperComponent
        render(DIV) do
          "test = #{TodoItem.first.test}"
        end
      end
    end
    expect(page).to have_content('test = 1')
  end

  it "can update the server method" do
    evaluate_ruby("TodoItem.first.test!")
    expect(page).to have_content('test = 2')
  end

  it "when updating the server method it returns the current value while waiting for the promise" do
    expect_evaluate_ruby("TodoItem.first.test!").to eq(2)
  end

  it "returns the default value on the first call while waiting for the promise" do
    expect_evaluate_ruby("TodoItem.new.test").to eq(0)
  end

  it "works with the load method" do
    expect_promise do
      new_todo = TodoItem.new
      ReactiveRecord.load do
        new_todo.test
      end
    end.to eq(5)
  end

  it "the server method can access any unsaved associations" do
    expect_promise do
      test_model = TestModel.new
      ChildModel.new(test_model: test_model)
      ReactiveRecord.load do
        test_model.test
      end
    end.to eq(1)
    expect(TestModel.count).to be_zero
    expect(ChildModel.count).to be_zero
  end
end
