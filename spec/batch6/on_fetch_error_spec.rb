require 'spec_helper'
require 'test_components'

describe "Hyperloop.on_error (for fetches) ", js: true do

  before(:all) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperloop.configuration do |config|
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
      regulate_class_connection { self }
    end
    ActiveRecord::Base.regulate_scope unscoped: nil
    ApplicationController.acting_user = User.new(first_name: 'fred')
    size_window(:large, :landscape)
    client_option raise_on_js_errors: :off
  end

  after(:each) do
    ['ApplicationRecord', 'TodoItem', 'Comment'].each do |klass|
      Object.send(:remove_const, klass.to_sym) && load("#{klass.underscore}.rb") rescue nil
    end
    ApplicationController.acting_user = nil
  end

  it 'call Hyperloop.on_error for access violations' do
    TodoItem.class_eval do
      TodoItem.regulate_relationship(:comments) { acting_user == user }
    end
    todo_item1 = TodoItem.create(user: ApplicationController.acting_user)
    todo_item2 = TodoItem.create(user: nil)
    Comment.create(todo_item: todo_item1)
    Comment.create(todo_item: todo_item1)
    # expect(Hyperloop).to receive(:on_error).once.with(
    #   Hyperloop::AccessViolation,
    #   :fetch_error,
    #   'acting_user' => ApplicationController.acting_user,
    #   'controller' => kind_of(ActionController::Base),
    #   'pending_fetches' => [['TodoItem', ['find_by', { 'id' => 2 }], 'comments', '*count']],
    #   'models' => [],
    #   'associations' => []
    # )
    expect(Hyperloop).to receive(:on_error).once.with(
      Hyperloop::AccessViolation,
      :scoped_permission_not_granted,
      anything
    )
    expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item1.id}).comments.count }")
      .to eq(2)
    expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item2.id}).comments.count }")
      .not_to eq(0)
  end

  it 'call ReactiveRecord.on_fetch_error for errors raised by models' do
    TodoItem.class_eval do
      def title
        raise 'Bogus'
      end
    end
    TodoItem.create(user: nil)
    expect(Hyperloop).to receive(:on_error).once.with(
      Exception,
      :fetch_error,
      hash_including(:acting_user, :controller, :pending_fetches, :models, :associations)
    )
    evaluate_ruby('TodoItem.find(1).title')
    wait_for_ajax
  end
end
