require 'spec_helper'
require 'test_components'

describe "Hyperstack.on_error (for fetches) ", js: true do

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

  it 'call Hyperstack.on_error for access violations on find_by' do
    TodoItem.class_eval do
      TodoItem.regulate_relationship(:comments) { acting_user == user }
      def view_permitted?(_attribute)
        false
      end
    end
    todo_item = TodoItem.create(user: nil, title: 'secret')
    expect(Hyperstack).to receive(:on_error).at_least(:once)
    .with('find_by', kind_of(ActiveRecord::Relation), kind_of(Hash), kind_of(String))
    expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item.id}) }").to be_nil
  end

  it 'call Hyperstack.on_error for access violations on other operations' do
    TodoItem.class_eval do
      TodoItem.regulate_relationship(:comments) { acting_user == user }
      # for this test allow the item's attributes to be viewed
      def view_permitted?(_attribute)
        true
      end
    end
    todo_item1 = TodoItem.create(user: ApplicationController.acting_user)
    todo_item2 = TodoItem.create(user: nil)
    Comment.create(todo_item: todo_item1)
    Comment.create(todo_item: todo_item1)
    expect(Hyperstack).to receive(:on_error).once.with(
      'ReactiveRecord::Operations::Fetch',
      instance_of(Hyperstack::AccessViolation),
      instance_of(Hash),
      instance_of(String)
    )
    expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item1.id}).comments.count }")
      .to eq(2)
    expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item2.id}).comments.count }")
      .not_to eq(0)
  end

  it 'call ReactiveRecord.on_fetch_error for errors raised by models' do
    allow_any_instance_of(TodoItem).to receive(:view_permitted?).and_return(true)
    isomorphic do
      TodoItem.class_eval do
        server_method(:explode) { raise RuntimeError }
      end
    end
    TodoItem.create(user: nil)
    expect(Hyperstack).to receive(:on_error).once.with(
      'ReactiveRecord::Operations::Fetch',
      instance_of(RuntimeError),
      hash_including(:acting_user, :controller, 'associations', 'pending_fetches', 'models'),
      instance_of(String)
    )
    evaluate_ruby('TodoItem.find(1).explode')
    wait_for_ajax
  end
end
