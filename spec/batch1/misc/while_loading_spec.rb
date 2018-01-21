require 'spec_helper'
require 'test_components'
require 'rspec-steps'


describe "while loading", js: true do

  before(:all) do
    class ReactiveRecord::Operations::Fetch < Hyperloop::ServerOp
      def self.semaphore
        @semaphore ||= Mutex.new
      end
      validate { self.class.semaphore.synchronize { true } }
    end
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
    # size_window(:small, :portrait)
    FactoryBot.create(:user, first_name: 'Lily', last_name: 'DaDog')
  end

  it "will display the while loading message for a fetch within a nested component" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class MyNestedGuy < Hyperloop::Component
          render(SPAN) do
            User.find_by_first_name('Lily').last_name
          end
        end
        class WhileLoadingTester < Hyperloop::Component
          render do
            DIV do
              MyNestedGuy {}
            end.while_loading do
              SPAN { 'loading...' }
            end
          end
        end
      end
      sleep 10000
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('DaDog', wait: 0)
    end
    expect(page).to have_content('DaDog')
    expect(page).not_to have_content('loading...', wait: 0)
  end

  it "loading and loaded blocks can return strings" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class WhileLoadingTester < Hyperloop::Component
          render do
            DIV do
              User.find_by_first_name('Lily').last_name
            end.while_loading do
              'loading...'
            end
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('DaDog', wait: 0)
      sleep 1
    end
    expect(page).to have_content('DaDog')
    expect(page).not_to have_content('loading...', wait: 0)
    sleep 1
  end

  it "The inner most while_loading will display only" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class MyNestedGuy < Hyperloop::Component
          render do
            DIV { User.find_by_first_name('Lily').last_name }
            .while_loading { SPAN { 'loading...' } }
          end
        end
        class WhileLoadingTester < Hyperloop::Component
          render do
            DIV do
              MyNestedGuy {}
            end.while_loading do
              SPAN { 'i should not display' }
            end
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('DaDog', wait: 0)
    end
    expect(page).to have_content('DaDog')
    expect(page).not_to have_content('loading...', wait: 0)
  end

  it "while loading can take a string param instead of a block" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class WhileLoadingTester < Hyperloop::Component
          render do
            DIV do
              User.find_by_first_name('Lily').last_name
            end
            .while_loading 'loading...'
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('DaDog', wait: 0)
    end
    expect(page).to have_content('DaDog')
    expect(page).not_to have_content('loading...', wait: 0)
  end

  it "while loading can take an element param instead of a block" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class WhileLoadingTester < Hyperloop::Component
          render do
            DIV do
              User.find_by_first_name('Lily').last_name
            end
            .while_loading(DIV { 'loading...' })
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('DaDog', wait: 0)
    end
    expect(page).to have_content('DaDog')
    expect(page).not_to have_content('loading...', wait: 0)
  end

  it "will display the while loading message on condition" do
    isomorphic do
      class FetchNow < Hyperloop::ServerOp
        dispatch_to { TestApplication }
      end
    end
    mount "WhileLoadingTester", {}, no_wait: true do
      class MyNestedGuy < Hyperloop::Component
        state fetch: false, scope: :shared
        FetchNow.on_dispatch { mutate.fetch(true) }
        render(SPAN) do
          if state.fetch
            User.find_by_first_name('Lily').last_name
          else
            'no fetch yet chet'
          end
        end
      end
      class WhileLoadingTester < Hyperloop::Component
        render do
          DIV do
            MyNestedGuy {}
          end.while_loading do
            SPAN { 'loading...' }
          end
        end
      end
    end
    expect(page).to have_content('no fetch yet chet')
    expect(page).not_to have_content('loading...', wait: 0)
    expect(page).not_to have_content('DaDog', wait: 0)
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      FetchNow.run
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('DaDog', wait: 0)
      expect(page).not_to have_content('no fetch yet chet', wait: 0)
    end
    expect(page).to have_content('DaDog')
    expect(page).not_to have_content('loading...', wait: 0)
    expect(page).not_to have_content('no fetch yet chet', wait: 0)
  end

end
