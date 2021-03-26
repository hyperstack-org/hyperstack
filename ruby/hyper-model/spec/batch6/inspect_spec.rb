require 'spec_helper'
require 'test_components'
require 'reactive_record_factory'
require 'rspec-steps'

RSpec::Steps.steps 'ActiveRecord::Base.inspect displays', js: true do
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
    TodoItem.do_not_synchronize
  end

  after(:all) do
    ['TodoItem'].each do |klass|
      Object.send(:remove_const, klass.to_sym) && load("#{klass.underscore}.rb") rescue nil
    end
  end

  before(:step) do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
    client_option raise_on_js_errors: :off
  end

  it 'shows the backing record id and actual record id' do
    evaluate_ruby "TodoItem.new(title: 'foo')"
    backing_record_id = evaluate_ruby(
      'ReactiveRecord::Operations::Base::FORMAT % TodoItem.find_by_title("foo").backing_record.object_id'
    )
    record_id = evaluate_ruby(
      'ReactiveRecord::Operations::Base::FORMAT % TodoItem.find_by_title("foo").object_id'
    )
    expect_evaluate_ruby('TodoItem.find_by(title: "foo").inspect')
    .to match(/<TodoItem:#{backing_record_id} \(#{record_id}\)/)
  end

  it 'new records with attributes (but not relationships)' do
    expect_evaluate_ruby do
      TodoItem.new(title: 'test', user: User.new).inspect
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[new {\"title\"=>\"test\"}\] >/
  end

  it 'loading records with the vector' do
    expect_evaluate_ruby do
      TodoItem.find_by_title('test2').inspect
    end.to match(/<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[loading TodoItem,find_by,{\"title\"=>\"test2\"}\] >/)
  end

  it 'loaded records with the primary key value' do
    TodoItem.create(title: 'test3')
    expect_promise do
      ReactiveRecord.load do
        TodoItem.find_by_title('test3').itself
      end.then do |loaded_item|
        loaded_item.inspect
      end
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[loaded id: 1\] >/
  end

  it 'changed records with the new attributes' do
    expect_evaluate_ruby do
      TodoItem.find_by_title('test3').tap do |todo|
        todo.title = 'new title'
        todo.user = User.new
      end.inspect
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[changed id: 1 {\"title\"=>\[\"test3\", \"new title\"\]}\] >/
  end

  it 'destroyed records with the primary key value' do
    expect_promise do
      todo = TodoItem.find_by_title('test3')
      todo.destroy.then do
        todo.inspect
      end
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[destroyed id: 1\] >/
  end

  it 'new records with the errors after attempting to save' do
    TodoItem.validates :title, presence: true
    expect_promise do
      todo = TodoItem.new(description: 'this has no title')
      todo.save.then do
        todo.inspect
      end
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[errors {\"title\"=>\[\"can't be blank\"\]}\] >/
  end

  it 'updated records with the errors after attempting to save' do
    expect_promise do
      todo = TodoItem.new(title: 'test4')
      todo.save.then do
        todo.title = nil
        todo.save
      end.then do
        todo.inspect
      end
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[errors id: #{TodoItem.find_by_title('test4').id} {\"title\"=>\[\"can't be blank\"\]}\] >/
  end

  it 'new records with the errors after attempting to save (deprecated error handler)' do

    evaluate_ruby do
      class ReactiveRecord::Base
        def errors
          @errors ||= ActiveModel::Error.new
        end
      end
    end

    TodoItem.validates :title, presence: true
    expect_promise do
      todo = TodoItem.new(description: 'this has no title')
      todo.save.then do
        todo.inspect
      end
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[errors {\"title\"=>\[\"can't be blank\"\]}\] >/
  end

  it 'updated records with the errors after attempting to save (deprecated error handler)' do
    expect_promise do
      todo = TodoItem.new(title: 'test5')
      todo.save.then do
        todo.title = nil
        todo.save
      end.then do
        todo.inspect
      end
    end.to match /<TodoItem:0x[0-9a-f]+ \(0x[0-9a-f]+\) \[errors id: #{TodoItem.find_by_title('test5').id} {\"title\"=>\[\"can't be blank\"\]}\] >/
  end
end
