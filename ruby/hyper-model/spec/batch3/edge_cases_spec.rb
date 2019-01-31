require 'spec_helper'
require 'test_components'

describe "reactive-record edge cases", js: true do

  before(:all) do
    # Hyperstack.configuration do |config|
    #   config.transport = :simple_poller
    #   # slow down the polling so wait_for_ajax works
    #   config.opts = { seconds_between_poll: 2 }
    # end

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

  it "will load all the policies before the first broadcast" do
    expect(defined? SomeModelPolicy).to be_falsy
    User.create(name: 'Fred')
    expect(defined? SomeModelPolicy).to be_truthy
  end


  it "prerenders a belongs to relationship" do
    # must be first otherwise check for ajax fails because of race condition
    # with previous test
    user_item = User.create(name: 'Fred')
    todo_item = TodoItem.create(title: 'test-todo', user: user_item)
    mount "PrerenderTest", {}, render_on: :server_only do
      class PrerenderTest < HyperComponent
        render(DIV) do
          TodoItem.first.user.name
        end
      end
    end
    page.should have_content("Fred")
  end

  it "trims the association tree" do
    5.times do |i|
      user = FactoryBot.create(:user, first_name: i) unless i == 3
      FactoryBot.create(:todo, title: "User #{i}'s todo", owner: user)
    end
    expect_promise do
      HyperMesh.load do
        Todo.all.collect do |todo|
          todo.owner && todo.owner.first_name
        end.compact
      end
    end.to contain_exactly('0', '1', '2', '4')
  end

  it "does not double count local saves" do
    expect_promise do
      HyperMesh.load do
        Todo.count
      end.then do |count|
        Todo.create(title: 'test todo')
      end.then do
        Todo.count
      end
    end.to eq(1)
  end

  it "fetches data during prerendering" do
    5.times do |i|
      FactoryBot.create(:todo, title: "Todo #{i}")
    end
    # cause spec to fail if there are attempts to fetch data after prerendering
    hide_const 'ReactiveRecord::Operations::Fetch'
    mount "TestComponent77", {}, render_on: :both do
      class TestComponent77 < HyperComponent
        render(UL) do
          Todo.each do |todo|
            LI { todo.title }
          end
        end
      end
    end
    Todo.all.each do |todo|
      page.should have_content(todo.title)
    end
  end

  it "the limit and offset predefined scopes work" do
    5.times do |i|
      FactoryBot.create(:todo, title: "Todo #{i}")
    end
    mount "TestComponent77" do
      class TestComponent77 < HyperComponent
        render(UL) do
          Todo.limit(2).offset(3).each do |todo|
            LI { todo.title }
          end
        end
      end
    end
    Todo.limit(2).offset(3).each do |todo|
      page.should have_content(todo.title)
    end
  end

  it 'will return nil instead of raising an access violation for finder methods' do
    FactoryBot.create(:todo, title: 'secret')
    expect_promise do
      Hyperstack::Model.load do
        Todo.find_by_title('secret')
      end
    end.to be_nil
    expect_promise do
      Hyperstack::Model.load do
        Todo.find(2)
      end
    end.to be_nil
    expect_promise do
      Hyperstack::Model.load do
        Todo.find_by(title: 'secret')
      end
    end.to be_nil
  end

  describe 'can use finder methods on scopes' do
    before(:each) do
      isomorphic do
        Todo.finder_method :with_title do |title|
          find_by_title(title)
        end
        Todo.scope :completed, -> () { where(completed: true) }
      end
      FactoryBot.create(:todo, title: 'todo 1', completed: true)
      FactoryBot.create(:todo, title: 'todo 2', completed: true)
      FactoryBot.create(:todo, title: 'todo 1', completed: false)
      FactoryBot.create(:todo, title: 'todo 2', completed: false)
      FactoryBot.create(:todo, title: 'secret', completed: true)
    end
    it 'find_by_xxx' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by_title('todo 2').id
        end
      end.to eq(Todo.completed.find_by_title('todo 2').id)
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by_title('todo 3')
        end
      end.to be_nil
    end
    it 'find' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(2).title
        end
      end.to eq(Todo.completed.find(2).title)
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(3)
        end
      end.to be_nil
    end
    it 'find_by' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by(title: 'todo 2').id
        end
      end.to eq(Todo.completed.find_by(title: 'todo 2').id)
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by(title: 'todo 3')
        end
      end.to be_nil
    end
    it "and will return nil unless access is allowed" do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by_title('secret')
        end
      end.to be_nil
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(5)
        end
      end.to be_nil
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by(title: 'secret')
        end
      end.to be_nil
    end
  end
end
