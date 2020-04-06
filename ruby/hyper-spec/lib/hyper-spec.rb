require 'capybara/rspec'
require 'opal'
require 'selenium-webdriver'

require 'hyper-spec/component_test_helpers'
require 'hyper-spec/version'
require 'hyper-spec/wait_for_ajax'
require 'selenium/web_driver/firefox/profile'

RSpec.configure do |config|
  config.include HyperSpec::ComponentTestHelpers
  config.include HyperSpec::WaitForAjax
  config.include Capybara::DSL

  config.mock_with :rspec

  config.add_setting :debugger_width, default: nil

  config.before(:each) do
    Hyperstack.class_eval do
      def self.on_server?
        true
      end
    end if defined?(Hyperstack)
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
RSpec.configure do |config|
  config.add_setting :wait_for_initialization_time
  config.wait_for_initialization_time = 3
  Capybara.default_max_wait_time = 10

  Capybara.register_driver :chrome do |app|
    options = {}
    options.merge!(
      w3c: false,
      args: %w[auto-open-devtools-for-tabs]) #,
      #prefs: { 'devtools.open_docked' => false, "devtools.currentDockState" => "undocked", devtools: {currentDockState: :undocked} }
    #) unless ENV['NO_DEBUGGER']
    # this does not seem to work properly.  Don't document this feature yet.
    #options['mobileEmulation'] = { 'deviceName' => ENV['DEVICE'].tr('-', ' ') } if ENV['DEVICE']
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(chromeOptions: options, 'goog:loggingPrefs' => {browser: 'ALL'})
    # Capybara::Selenium::Driver.new(app, :browser => :chrome,   desired_capabilities: {
    #   "chromeOptions" => {
    #     w3c: false
    #   },
    #   'goog:loggingPrefs' => {browser: 'ALL'}
    # })
    Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
  end

  Capybara.register_driver :chrome_headless_docker_travis do |app|
    options = ::Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    Capybara::Selenium::Driver.new(app, browser: :chrome, :driver_path => "/usr/lib/chromium-browser/chromedriver", options: options)
  end

  Capybara.register_driver :firefox do |app|
    Capybara::Selenium::Driver.new(app, browser: :firefox)
  end

  Capybara.register_driver :firefox_headless do |app|
    options = Selenium::WebDriver::Firefox::Options.new
    options.headless!
    Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
  end

  Capybara.register_driver :selenium_with_firebug do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    ENV['FRAME_POSITION'] && profile.frame_position = ENV['FRAME_POSITION']
    profile.enable_firebug
    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
    Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
  end

  Capybara.register_driver :safari do |app|
    Capybara::Selenium::Driver.new(app, browser: :safari)
  end

  Capybara.javascript_driver =
    case ENV['DRIVER']
    when 'beheaded' then :firefox_headless
    when 'chrome' then :chrome
    when 'ff' then :selenium_with_firebug
    when 'firefox' then :firefox
    when 'headless' then :selenium_chrome_headless
    when 'safari' then :safari
    when 'travis' then :chrome_headless_docker_travis
    else :selenium_chrome_headless
    end

end
