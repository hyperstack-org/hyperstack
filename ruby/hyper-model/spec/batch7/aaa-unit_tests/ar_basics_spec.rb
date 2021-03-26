require 'spec_helper'
require 'test_components'

describe 'ActiveRecord client side basics', js: true do

  before(:all) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = 'MY_TEST_ID'
    Pusher.key =    'MY_TEST_KEY'
    Pusher.secret = 'MY_TEST_SECRET'
    require 'pusher-fake/support/base'

    Hyperstack.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = 'synchromesh'
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret, use_tls: false}.merge(PusherFake.configuration.web_options)
    end
  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all unless policy.obj.is_a?(Todo) && policy.obj.title == 'secret' }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  describe 'finder methods' do

    before(:each) do
      isomorphic do
        Todo.finder_method :with_title do |title|
          find_by_title(title)
        end
        Todo.scope :completed, -> () { where(completed: true) }
      end
      FactoryBot.create(:todo, title: 'todo 1')
      FactoryBot.create(:todo, title: 'todo 2')
      FactoryBot.create(:todo, title: 'todo 3')
      FactoryBot.create(:todo, title: 'todo 4')
      FactoryBot.create(:todo, title: 'todo 5')
    end

    it 'find with id' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.find(4).id
        end
      end.to eq(4)
    end

    it 'find with id array' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.find(1,2,3,4,5).map(&:title)
        end
      end.to eq(Todo.find(1,2,3,4,5).map(&:title))
    end

    it 'find with id array returns nil value' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.find(4,5,6).map {|todo| todo.is_a?(Todo) ? todo.title : todo}
        end
      end.to eq(Todo.find(4,5).map(&:title) + [nil])
    end
  end
end
