require 'spec_helper'
require 'test_components'

describe "reactive-record edge cases", js: true do

  before(:all) do
    # Hyperloop.configuration do |config|
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

    Hyperloop.configuration do |config|
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
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
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
      class TestComponent77 < Hyperloop::Component
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

  it "prerenders a belongs to relationship" do
    user_item = User.create(name: 'Fred')
    todo_item = TodoItem.create(title: 'test-todo', user: user_item)
    mount "PrerenderTest", {}, render_on: :server_only do
      class PrerenderTest < Hyperloop::Component
        render(DIV) do
          TodoItem.first.user.name
        end
      end
    end
    page.should have_content("Fred")
  end

  it "the limit and offset predefined scopes work" do
    5.times do |i|
      FactoryBot.create(:todo, title: "Todo #{i}")
    end
    mount "TestComponent77" do
      class TestComponent77 < Hyperloop::Component
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
end
