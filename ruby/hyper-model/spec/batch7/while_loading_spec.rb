require 'spec_helper'
require 'test_components'
require 'rspec-steps'


describe "while loading", js: true do

  before(:all) do
    ReactiveRecord::Operations::Fetch.class_eval do
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

    Hyperstack.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end
  end

  before(:each) do
    client_option raise_on_js_errors: :off

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
    FactoryBot.create(:user, first_name: 'Coffee', last_name: 'Boxer')
  end

  it "will display the while loading message for a fetch within a nested component" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class MyNestedGuy < HyperComponent
          render(SPAN) do
            "#{User.find_by_first_name('Lily').last_name} is a dog"
          end
        end
        class WhileLoadingTester < HyperComponent
          include Hyperstack::Component::WhileLoading
          render do
            if resources_loaded?
              DIV do
                MyNestedGuy {}
              end
            else
              SPAN { 'loading...' }
            end
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('is a dog', wait: 0)
    end
    expect(page).to have_content('DaDog is a dog')
    expect(page).not_to have_content('loading...', wait: 0)
  end

  it "will display the while loading message for a fetch within a nested component when attached to that component" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class MyNestedGuy < HyperComponent
          render(SPAN) do
            "#{User.find_by_first_name('Lily').last_name} is a dog"
          end
        end
        class WhileLoadingTester < HyperComponent
          include Hyperstack::Component::WhileLoading
          render(DIV) do
            if resources_loaded?
              MyNestedGuy {}
            else
              SPAN { 'loading...' }
            end
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('is a dog', wait: 0)
    end
    expect(page).to have_content('DaDog is a dog')
    expect(page).not_to have_content('loading...', wait: 0)
  end

  it "The inner most while_loading will display only" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class MyNestedGuy < HyperComponent
          include Hyperstack::Component::WhileLoading
          render do
            if resources_loaded?
              DIV { "#{User.find_by_first_name('Lily').last_name} is a dog" }
            else
              SPAN { 'loading...' }
            end
          end
        end
        class WhileLoadingTester < HyperComponent
          include Hyperstack::Component::WhileLoading
          render do
            if resources_loaded?
              DIV do
                MyNestedGuy {}
              end
            else
              SPAN { 'i should not display' }
            end
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('is a dog', wait: 0)
    end
    expect(page).to have_content('DaDog is a dog')
    expect(page).not_to have_content('i should not display', wait: 0)
  end

  # it "while loading can take a string param instead of a block" do
  #   ReactiveRecord::Operations::Fetch.semaphore.synchronize do
  #     mount "WhileLoadingTester", {}, no_wait: true do
  #       class WhileLoadingTester < HyperComponent
  #         render do
  #           DIV do
  #             User.find_by_first_name('Lily').last_name
  #           end
  #           .while_loading 'loading...'
  #         end
  #       end
  #     end
  #     expect(page).to have_content('loading...')
  #     expect(page).not_to have_content('DaDog', wait: 0)
  #   end
  #   expect(page).to have_content('DaDog')
  #   expect(page).not_to have_content('loading...', wait: 0)
  # end
  #
  # it "while loading can take an element param instead of a block" do
  #   ReactiveRecord::Operations::Fetch.semaphore.synchronize do
  #     mount "WhileLoadingTester", {}, no_wait: true do
  #       class WhileLoadingTester < HyperComponent
  #         render do
  #           DIV do
  #             User.find_by_first_name('Lily').last_name
  #           end
  #           .while_loading(DIV { 'loading...' })
  #         end
  #       end
  #     end
  #     expect(page).to have_content('loading...')
  #     expect(page).not_to have_content('DaDog', wait: 0)
  #   end
  #   expect(page).to have_content('DaDog')
  #   expect(page).not_to have_content('loading...', wait: 0)
  # end
  #
  # it "achieving while_loading behavior with state variables" do
  #   ReactiveRecord::Operations::Fetch.semaphore.synchronize do
  #     mount "WhileLoadingTester", {}, no_wait: true do
  #       class MyComponent < HyperComponent
  #         render do
  #           SPAN { 'loading...' }
  #         end
  #       end
  #
  #       class WhileLoadingTester < HyperComponent
  #
  #         before_mount do
  #           ReactiveRecord.load do
  #             User.find_by_first_name('Lily').last_name
  #           end.then do |last_name|
  #             mutate @last_name = last_name
  #           end
  #         end
  #
  #         render do
  #           if @last_name
  #             DIV { @last_name }
  #           else
  #             MyComponent {}
  #           end
  #         end
  #       end
  #     end
  #     expect(page).to have_content('loading...')
  #     expect(page).not_to have_content('DaDog', wait: 0)
  #   end
  #   expect(page).to have_content('DaDog')
  #   expect(page).not_to have_content('loading...', wait: 0)
  # end
  #
  # it "while loading display an application defined element" do
  #   ReactiveRecord::Operations::Fetch.semaphore.synchronize do
  #     mount "WhileLoadingTester", {}, no_wait: true do
  #       class MyComponent < HyperComponent
  #         render do
  #           SPAN { 'loading...' }
  #         end
  #       end
  #       class WhileLoadingTester < HyperComponent
  #         render do
  #           DIV do
  #             User.find_by_first_name('Lily').last_name
  #           end
  #           .while_loading do
  #             MyComponent {}
  #           end
  #         end
  #       end
  #     end
  #     expect(page).to have_content('loading...')
  #     expect(page).not_to have_content('DaDog', wait: 0)
  #   end
  #   expect(page).to have_content('DaDog')
  #   expect(page).not_to have_content('loading...', wait: 0)
  # end

  it "while loading works when number of children changes (i.e. relationships)" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "WhileLoadingTester", {}, no_wait: true do
        class WhileLoadingTester < HyperComponent
          include Hyperstack::Component::WhileLoading
          render do
            if resources_loaded?
              UL { User.each { |user| LI { user.last_name } } }
            else
              'loading...'
            end
          end
        end
      end
      expect(page).to have_content('loading...')
      expect(page).not_to have_content('DaDog', wait: 0)
      expect(page).not_to have_content('Boxer', wait: 0)
    end
    expect(page).to have_content('DaDog')
    expect(page).to have_content('Boxer')
    expect(page).not_to have_content('loading...', wait: 0)
  end


  it "will display the while loading message on condition" do
    isomorphic do
      class FetchNow < Hyperstack::ServerOp
        dispatch_to { TestApplication }
      end
    end
    mount "WhileLoadingTester", {}, no_wait: true do
      class MyNestedGuy < HyperComponent
        self.class.attr_reader :fetch
        receives(FetchNow) { mutate @fetch = true }
        render(SPAN) do
          if self.class.fetch
            User.find_by_first_name('Lily').last_name
          else
            'no fetch yet chet'
          end
        end
      end
      class WhileLoadingTester < HyperComponent
        include Hyperstack::Component::WhileLoading
        render do
          if resources_loaded?
            DIV { MyNestedGuy {} }
          else
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
