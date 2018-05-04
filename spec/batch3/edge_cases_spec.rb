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

  xit "fetches data during prerendering" do # server_only not working!
    # test for fix in prerendering fetch which was causing security violations
    5.times do |i|
      FactoryBot.create(:todo, title: "Todo #{i}")
    end
    mount "TestComponent77", {}, render_on: :both do
      class TestComponent77 < Hyperloop::Component
        render(UL) do
          puts "Todo defined? #{defined? Todo} class? #{Todo.class}"
          LI { "fred" }
          #Todo.each do |todo|
          #   # try Todo.find_by_title ... as well
          #   LI { todo.title }
          # end
        end
      end
    end
    binding.pry
  end
end
