require 'capybara/rspec'
require 'capybara/poltergeist'
require 'opal'
require 'selenium-webdriver'

require 'hyper-spec/component_test_helpers'
require 'hyper-spec/rails/engine'
require 'hyper-spec/version'
require 'hyper-spec/wait_for_ajax'
require 'react/isomorphic_helpers'
require 'selenium/web_driver/firefox/profile'

RSpec.configure do |config|
  config.include HyperSpec::ComponentTestHelpers
  config.include HyperSpec::WaitForAjax
  config.include Capybara::DSL

  config.mock_with :rspec

  if defined?(HyperMesh)
    config.before(:each) do
      HyperMesh.class_eval do
        def self.on_server?
          true
        end
      end
    end
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

  # # In case Google ever fixes chromedriver to work with Opal...
  # Capybara.register_driver :chrome do |app|
  #   caps = Selenium::WebDriver::Remote::Capabilities.chrome(
  #     'chromeOptions' => { 'args' => ['--window-size=200,200'] }
  #   )
  #
  #   Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: caps)
  # end

  Capybara.register_driver :poltergeist do |app|
    options = {
      js_errors: false, timeout: 180, inspector: true,
      phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes']
    }.tap do |hash|
      unless ENV['SHOW_LOGS']
        hash[:phantomjs_logger] = StringIO.new
        hash[:logger] = StringIO.new
      end
    end

    Capybara::Poltergeist::Driver.new(app, options)
  end

  Capybara.register_driver :selenium_with_firebug do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile.frame_position = ENV['DRIVER'] && ENV['DRIVER'][2]
    profile.enable_firebug

    Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
  end

  Capybara.javascript_driver =
    if ENV['DRIVER'] =~ /^ff/
      :selenium_with_firebug
    # elsif ENV['DRIVER'] == 'chrome'
    #   Capybara.javascript_driver = :chrome
    else
      :poltergeist
    end
end
