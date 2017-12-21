require 'capybara/rspec'
require 'opal'
require 'selenium-webdriver'

require 'hyper-spec/component_test_helpers'
require 'hyper-spec/rails/engine'
require 'hyper-spec/version'
require 'hyper-spec/wait_for_ajax'
require 'selenium/web_driver/firefox/profile'

RSpec.configure do |config|
  config.include HyperSpec::ComponentTestHelpers
  config.include HyperSpec::WaitForAjax
  config.include Capybara::DSL

  config.mock_with :rspec

  config.add_setting :debugger_width, default: 0

  config.before(:each) do
    Hyperloop.class_eval do
      def self.on_server?
        true
      end
    end if defined?(Hyperloop)
    # for compatibility with HyperMesh
    HyperMesh.class_eval do
      def self.on_server?
        true
      end
    end if defined?(HyperMesh)
  end

  config.before(:each, js: true) do
    size_window
  end

  config.after(:each, js: true) do
    page.instance_variable_set('@hyper_spec_mounted', false)
  end

  config.after(:each) do |example|
    unless example.exception
      PusherFake::Channel.reset if defined? PusherFake
    end
  end
end

# Capybara config
RSpec.configure do |_config|
  Capybara.default_max_wait_time = 10

  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_arg('auto-open-devtools-for-tabs') unless ENV['NO_DEBUGGER']
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.register_driver :firefox do |app|
    Capybara::Selenium::Driver.new(app, browser: :firefox)
  end

  Capybara.register_driver :selenium_with_firebug do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    ENV['FRAME_POSITION'] && profile.frame_position = ENV['FRAME_POSITION']
    profile.enable_firebug

    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)

    Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
  end

  Capybara.javascript_driver =
    case ENV['DRIVER']
    when 'ff' then :selenium_with_firebug
    when 'firefox' then :firefox
    when 'chrome' then :chrome
    else :selenium_chrome_headless
    end
end
