# hyper-spec
require 'action_view'
require 'opal'
require 'unparser'
require 'method_source'
require 'filecache'

require 'capybara/rspec'
require 'hyper-spec/internal/client_execution'
require 'hyper-spec/internal/component_mount'
require 'hyper-spec/internal/controller'
require 'hyper-spec/internal/copy_locals'
require 'hyper-spec/internal/patches'
require 'hyper-spec/internal/rails_controller_helpers'
require 'hyper-spec/internal/time_cop.rb'
require 'hyper-spec/internal/window_sizing'

require 'hyper-spec/controller_helpers'

require 'hyper-spec/wait_for_ajax'

require 'hyper-spec/helpers'
require 'hyper-spec/expectations'

require 'parser/current'
if defined?(Selenium::WebDriver::Firefox)
  require 'selenium/web_driver/firefox/profile'
end
require 'selenium-webdriver'

require 'hyper-spec/version'


begin
  require 'pry'
rescue LoadError
  nil
end

# opt-in to most recent AST format:
Parser::Builders::Default.emit_lambda              = true
Parser::Builders::Default.emit_procarg0            = true
Parser::Builders::Default.emit_encoding            = true
Parser::Builders::Default.emit_index               = true
Parser::Builders::Default.emit_arg_inside_procarg0 = true
Parser::Builders::Default.emit_forward_arg         = true
Parser::Builders::Default.emit_kwargs              = true
Parser::Builders::Default.emit_match_pattern       = true

# not available in parser 2.3
if Parser::Builders::Default.respond_to? :emit_arg_inside_procarg0
  Parser::Builders::Default.emit_arg_inside_procarg0 = true
end

module HyperSpec
  if defined? Pry
    # add a before eval hook to pry so we can capture the source
    class << self
      attr_accessor :current_pry_code_block
      Pry.hooks.add_hook(:before_eval, 'hyper_spec_code_capture') do |code|
        HyperSpec.current_pry_code_block = code
      end
    end
  end

  def self.reset_between_examples
    @reset_between_examples ||= []
  end

  def self.reset_between_examples?
    RSpec.configuration.reset_between_examples
  end

  def self.reset_sessions!
    Capybara.old_reset_sessions!
  end
end

# TODO: figure out why we need this patch - its because we are on an old version
# of Selenium Webdriver, but why?
require 'selenium-webdriver'

module Selenium
  module WebDriver
    module Chrome
      module Bridge
        COMMANDS = remove_const(:COMMANDS).dup
        COMMANDS[:get_log] = [:post, 'session/:session_id/log']
        COMMANDS.freeze

        def log(type)
          data = execute :get_log, {}, type: type.to_s

          Array(data).map do |l|
            begin
              LogEntry.new l.fetch('level', 'UNKNOWN'), l.fetch('timestamp'), l.fetch('message')
            rescue KeyError
              next
            end
          end
        end
      end
    end
  end
end

module Capybara
  class << self
    alias old_reset_sessions! reset_sessions!
    def reset_sessions!
      old_reset_sessions! if HyperSpec.reset_between_examples?
    end
  end
end

RSpec.configure do |config|
  config.add_setting :reset_between_examples, default: true
  config.before(:all, no_reset: true) do
    HyperSpec.reset_between_examples << RSpec.configuration.reset_between_examples
    RSpec.configuration.reset_between_examples = false
  end
  config.before(:all, no_reset: false) do
    HyperSpec.reset_between_examples << RSpec.configuration.reset_between_examples
    RSpec.configuration.reset_between_examples = true
  end
  config.after(:all) do
    HyperSpec.reset_sessions! unless HyperSpec.reset_between_examples?
    # If rspecs step is used first in a file, it will NOT call config.before(:all) causing the
    # reset_between_examples stack to be mismatched, so we check, if its already empty we
    # just leave.
    next if HyperSpec.reset_between_examples.empty?

    RSpec.configuration.reset_between_examples = HyperSpec.reset_between_examples.pop
  end
  config.before(:each) do |example|
    insure_page_loaded(true) if example.metadata[:js] && !HyperSpec.reset_between_examples?
  end
end

RSpec.configure do |config|
  config.include HyperSpec::Helpers
  config.include HyperSpec::WaitForAjax
  config.include Capybara::DSL

  config.mock_with :rspec

  config.add_setting :debugger_width, default: nil

  config.before(:each) do
    if defined?(Hyperstack)
      Hyperstack.class_eval do
        def self.on_server?
          true
        end
      end
    end
    # for compatibility with HyperMesh
    if defined?(HyperMesh)
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
RSpec.configure do |config|
  config.before(:each) do |example|
    HyperSpec::Internal::Controller.current_example = example
    HyperSpec::Internal::Controller.description_displayed = false
  end

  config.add_setting :wait_for_initialization_time
  config.wait_for_initialization_time = 3

  Capybara.default_max_wait_time = 10

  Capybara.register_driver :chrome do |app|
    options = {}
    options.merge!(
      w3c: false,
      args: %w[auto-open-devtools-for-tabs]
    )
    options['mobileEmulation'] = { 'deviceName' => ENV['DEVICE'].tr('-', ' ') } if ENV['DEVICE']
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      chromeOptions: options, 'goog:loggingPrefs' => { browser: 'ALL' }
    )
    Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
  end

  Capybara.register_driver :firefox do |app|
    Capybara::Selenium::Driver.new(app, browser: :firefox)
  end

  Capybara.register_driver :chrome_headless_docker_travis do |app|
    options = ::Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    Selenium::WebDriver::Chrome::Service.driver_path = '/usr/lib/chromium-browser/chromedriver'
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.register_driver :firefox_headless do |app|
    options = Selenium::WebDriver::Firefox::Options.new
    options.headless!
    Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
  end if defined?(Selenium::WebDriver::Firefox)

  Capybara.register_driver :selenium_with_firebug do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    ENV['FRAME_POSITION'] && profile.frame_position = ENV['FRAME_POSITION']
    profile.enable_firebug
    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
    Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
  end if defined?(Selenium::WebDriver::Firefox)

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
