require 'spec_helper'

describe 'defaultValue special handling', js: true do

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
    FactoryBot.create(:test_model, test_attribute: 'I have been loaded', completed: true)
  end

  it 'will not use the defaultValue param until data is loaded - unit test' do
    mount 'Tester' do
      class LoadableString
        def initialize(s)
          @s = s
        end
        def to_s
          if loading?
            React::RenderingContext.waiting_on_resources = true
            "loading..."
          else
            @s
          end
        end
        def loading?
          !React::State.get_state(self, 'loaded?')
        end
        def value
          self
        end
        def value=(x)
          React::State.set_state(self, 'loaded?', Time.now)
          @s = x
        end
      end
      class Tester < Hyperloop::Component
        include React::IsomorphicHelpers
        state :loaded, scope: :shared
        def self.loadable_string
          @loadable_string
        end
        before_first_mount do
          @loadable_string = LoadableString.new(self)
        end
        render(DIV) do
          INPUT(id: 'uncontrolled-input', defaultValue: Tester.loadable_string.value)
          INPUT(id: 'uncontrolled-checkbox', type: :checkbox, defaultChecked: -> () { Tester.loadable_string.to_s == 'I have been loaded' })
          SELECT(id: 'uncontrolled-select', defaultValue: Tester.loadable_string.value) do
            OPTION(value: 'loading...') { "loading..." }
            OPTION(value: 'I have been loaded') { "I have been loaded" }
            OPTION(value: 'another value') { "another value" }
            OPTION(value: 'set by user') { "set by user" }
          end
          TEXTAREA(id: 'uncontrolled-textarea', defaultValue: Tester.loadable_string.value)

          INPUT(id: 'controlled-input', value: Tester.loadable_string.value, valuex: Tester.loadable_string.value)
          .on(:change) { |evt| Tester.loadable_string.value = evt.target.value }
          INPUT(id: 'controlled-checkbox', type: :checkbox, checked: Tester.loadable_string.to_s == 'I have been loaded')
          .on(:change) { |evt| Tester.loadable_string.value = evt.target.checked ? 'I have been loaded' : 'The user clicked off the checkbox' }
          SELECT(id: 'controlled-select', value: Tester.loadable_string.value) do
            OPTION(value: 'loading...') { "loading..." }
            OPTION(value: 'I have been loaded') { "I have been loaded" }
            OPTION(value: 'another value') { "another value" }
            OPTION(value: 'set by user') { "set by user" }
          end
          .on(:change) { |evt| Tester.loadable_string.value = evt.target.value }
          TEXTAREA(id: 'controlled-textarea', value: Tester.loadable_string.value)
          .on(:change) { |evt| Tester.loadable_string.value = evt.target.value }
        end
      end
    end
    # initial value which is still loading
    expect(find('#uncontrolled-input').value).to eq('loading...')
    expect(find('#uncontrolled-checkbox')).not_to be_checked
    expect(find('#uncontrolled-select').value).to eq('loading...')
    expect(find('#uncontrolled-textarea').value).to eq('loading...')
    expect(find('#controlled-input').value).to eq('loading...')
    expect(find('#controlled-checkbox')).not_to be_checked
    expect(find('#controlled-select').value).to eq('loading...')
    expect(find('#controlled-textarea').value).to eq('loading...')

    # now we update so its loaded and the controlled and uncontrolled inputs will change
    evaluate_ruby("Tester.loadable_string.value = 'I have been loaded'")
    expect(find('#uncontrolled-input').value).to eq('I have been loaded')
    expect(find('#uncontrolled-checkbox')).to be_checked
    expect(find('#uncontrolled-select').value).to eq('I have been loaded')
    expect(find('#uncontrolled-textarea').value).to eq('I have been loaded')
    expect(find('#controlled-input').value).to eq('I have been loaded')
    expect(find('#controlled-checkbox')).to be_checked
    expect(find('#controlled-select').value).to eq('I have been loaded')
    expect(find('#controlled-textarea').value).to eq('I have been loaded')

    # now we update it again, but only the controlled inputs should change
    evaluate_ruby("Tester.loadable_string.value = 'another value'")
    expect(find('#uncontrolled-input').value).to eq('I have been loaded')
    expect(find('#uncontrolled-checkbox')).to be_checked
    expect(find('#uncontrolled-select').value).to eq('I have been loaded')
    expect(find('#uncontrolled-textarea').value).to eq('I have been loaded')
    expect(find('#controlled-input').value).to eq('another value')
    expect(find('#controlled-checkbox')).not_to be_checked
    expect(find('#controlled-select').value).to eq('another value')
    expect(find('#controlled-textarea').value).to eq('another value')

    # but if the user changes an input it will always change
    find('#uncontrolled-input').set 'I was set by the user'
    expect(find('#uncontrolled-input').value).to eq('I was set by the user')
    find('#uncontrolled-checkbox').set(false)
    expect(find('#uncontrolled-checkbox')).not_to be_checked
    find('#uncontrolled-select').find(:option, 'set by user').select_option
    expect(find('#uncontrolled-select').value).to eq('set by user')
    find('#uncontrolled-textarea').set 'I was set by the user'
    expect(find('#uncontrolled-textarea').value).to eq('I was set by the user')
    find('#controlled-input').set 'I was set by the user'
    expect(find('#controlled-input').value).to eq('I was set by the user')
    find('#controlled-checkbox').set(true)
    expect(find('#controlled-checkbox')).to be_checked
    expect_evaluate_ruby("Tester.loadable_string").to eq('I have been loaded')
    find('#controlled-select').find(:option, 'set by user').select_option
    expect(find('#controlled-select').value).to eq('set by user')
    find('#controlled-textarea').set 'text box set by the user'
    expect(find('#controlled-textarea').value).to eq('text box set by the user')
  end

  it "will properly update input tags when data is loaded or changed" do
    ReactiveRecord::Operations::Fetch.semaphore.synchronize do
      mount "InputTester", {}, no_wait: true do
        class MyNestedGuy < Hyperloop::Component
          render(SPAN) do
            "#{User.find_by_first_name('Lily').last_name} is a dog"
          end
        end
        class InputTester < Hyperloop::Component
          before_mount do
            @test_model = TestModel.first
          end
          render(DIV) do
            INPUT(id: 'uncontrolled-input', defaultValue: @test_model.test_attribute)
            INPUT(id: 'uncontrolled-checkbox', type: :checkbox, defaultChecked: @test_model.completed)
            SELECT(id: 'uncontrolled-select', defaultValue: @test_model.test_attribute) do
              OPTION(value: 'loading...') { "" }
              OPTION(value: 'I have been loaded') { "I have been loaded" }
              OPTION(value: 'another value') { "another value" }
              OPTION(value: 'set by user') { "set by user" }
            end
            TEXTAREA(id: 'uncontrolled-textarea', defaultValue: @test_model.test_attribute)

            INPUT(id: 'controlled-input', value: @test_model.test_attribute)
            .on(:change) { |evt| @test_model.test_attribute = evt.target.value }
            INPUT(id: 'controlled-checkbox', type: :checkbox, checked: @test_model.completed)
            .on(:change) { |evt| @test_model.completed = evt.target.checked }
            SELECT(id: 'controlled-select', value: @test_model.test_attribute) do
              OPTION(value: 'loading...') { "" }
              OPTION(value: 'I have been loaded') { "I have been loaded" }
              OPTION(value: 'another value') { "another value" }
              OPTION(value: 'set by user') { "set by user" }
            end
            .on(:change) { |evt| @test_model.test_attribute = evt.target.value }
            TEXTAREA(id: 'controlled-textarea', value: @test_model.test_attribute)
            .on(:change) { |evt| @test_model.test_attribute = evt.target.value }
          end
        end
      end
    end
    expect(page).not_to have_content('loading...', wait: 0)
    expect(find('#uncontrolled-input').value).to eq('I have been loaded')
    expect(find('#uncontrolled-checkbox')).to be_checked
    expect(find('#uncontrolled-select').value).to eq('I have been loaded')
    expect(find('#uncontrolled-textarea').value).to eq('I have been loaded')
    expect(find('#controlled-input').value).to eq('I have been loaded')
    expect(find('#controlled-checkbox')).to be_checked
    expect(find('#controlled-select').value).to eq('I have been loaded')
    expect(find('#controlled-textarea').value).to eq('I have been loaded')

    TestModel.first.update(test_attribute: 'another value', completed: false)
    expect(find('#uncontrolled-input').value).to eq('I have been loaded')
    expect(find('#uncontrolled-checkbox')).to be_checked
    expect(find('#uncontrolled-select').value).to eq('I have been loaded')
    expect(find('#uncontrolled-textarea').value).to eq('I have been loaded')
    expect(find('#controlled-input').value).to eq('another value')
    expect(find('#controlled-checkbox')).not_to be_checked
    expect(find('#controlled-select').value).to eq('another value')
    expect(find('#controlled-textarea').value).to eq('another value')

    find('#uncontrolled-input').set 'I was set by the user'
    expect(find('#uncontrolled-input').value).to eq('I was set by the user')

    find('#uncontrolled-checkbox').set(false)
    expect(find('#uncontrolled-checkbox')).not_to be_checked

    find('#uncontrolled-select').find(:option, 'set by user').select_option
    expect(find('#uncontrolled-select').value).to eq('set by user')

    find('#uncontrolled-textarea').set 'I was set by the user'
    expect(find('#uncontrolled-textarea').value).to eq('I was set by the user')

    find('#controlled-input').set 'I was also set by the user'
    expect(find('#controlled-input').value).to eq('I was also set by the user')
    evaluate_promise('TestModel.first.save')
    expect(TestModel.first.test_attribute).to eq('I was also set by the user')

    find('#controlled-checkbox').set(true)
    expect(find('#controlled-checkbox')).to be_checked
    evaluate_promise('TestModel.first.save')
    expect(TestModel.first.completed).to be_truthy

    find('#controlled-select').find(:option, 'set by user').select_option
    expect(find('#controlled-select').value).to eq('set by user')
    evaluate_promise('TestModel.first.save')
    expect(TestModel.first.test_attribute).to eq('set by user')

    find('#controlled-textarea').set 'text box set by the user'
    expect(find('#controlled-textarea').value).to eq('text box set by the user')
    evaluate_promise('TestModel.first.save')
    expect(TestModel.first.test_attribute).to eq('text box set by the user')
  end
end
