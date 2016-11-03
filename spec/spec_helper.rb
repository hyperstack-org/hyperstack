# spec/spec_helper.rb
ENV["RAILS_ENV"] ||= 'test'

require 'opal'
require 'opal-rspec'

def opal?
  RUBY_ENGINE == 'opal'
end

def ruby?
  !opal?
end

if RUBY_ENGINE == 'opal'
  require 'hyper-react'
  require File.expand_path('../support/react/spec_helpers', __FILE__)

  module Opal
    module RSpec
      module AsyncHelpers
        module ClassMethods
          def rendering(title, &block)
            klass = Class.new do
              include React::Component

              def self.block
                @block
              end

              def self.name
                "dummy class"
              end

              def render
                instance_eval &self.class.block
              end

              def self.should_generate(opts={}, &block)
                sself = self
                @self.async(@title, opts) do
                  expect_component_to_eventually(sself, &block)
                end
              end

              def self.should_immediately_generate(opts={}, &block)
                sself = self
                @self.it(@title, opts) do
                  element = build_element sself, {}
                  context = block.arity > 0 ? self : element
                  expect((element and context.instance_exec(element, &block))).to be(true)
                end
              end

            end
            klass.instance_variable_set("@block", block)
            klass.instance_variable_set("@self", self)
            klass.instance_variable_set("@title", "it can render #{title}")
            klass
          end
        end
      end
    end
  end


  RSpec.configure do |config|
    config.include React::SpecHelpers
    config.filter_run_including :opal => true
  end
end

if RUBY_ENGINE != 'opal'
  begin
    require File.expand_path('../test_app/config/environment', __FILE__)
  rescue LoadError
    puts 'Could not load test application. Please ensure you have run `bundle exec rake test_app`'
  end
  require 'rspec/rails'
  require 'timecop'

  Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

  RSpec.configure do |config|
    config.color = true
    config.fail_fast = ENV['FAIL_FAST'] || false
    config.fixture_path = File.join(File.expand_path(File.dirname(__FILE__)), "fixtures")
    config.infer_spec_type_from_file_location!
    config.mock_with :rspec
    config.raise_errors_for_deprecations!

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, comment the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    config.before :each do
      Rails.cache.clear
    end

    config.filter_run_including focus: true
    config.filter_run_excluding opal: true
    config.run_all_when_everything_filtered = true
  end

  FACTORY_GIRL = false

  #require 'rails_helper'
  require 'rspec'
  require 'rspec/expectations'
  begin
    require 'factory_girl_rails'
  rescue LoadError
  end
  require 'shoulda/matchers'
  require 'database_cleaner'
  require 'capybara/rspec'
  require 'capybara/rails'
  require 'support/component_helpers'
  require 'capybara/poltergeist'
  require 'selenium-webdriver'

  module React
    module IsomorphicHelpers
      def self.load_context(ctx, controller, name = nil)
        @context = Context.new("#{controller.object_id}-#{Time.now.to_i}", ctx, controller, name)
      end
    end
  end

  module WaitForAjax

    def wait_for_ajax
      Timeout.timeout(Capybara.default_max_wait_time) do
        begin
          sleep 0.25
        end until finished_all_ajax_requests?
      end
    end

    def running?
      result = page.evaluate_script("(function(active) {console.log('jquery is active? '+active); return active})(jQuery.active)")
      result && !result.zero?
    rescue Exception => e
      puts "something wrong: #{e}"
    end

    def finished_all_ajax_requests?
      unless running?
        sleep 1
        !running?
      end
    rescue Capybara::NotSupportedByDriverError
      true
    rescue Exception => e
      e.message == "jQuery is not defined"
    end

  end

  RSpec.configure do |config|
    config.include WaitForAjax
  end

  RSpec.configure do |config|
    # rspec-expectations config goes here. You can use an alternate
    # assertion/expectation library such as wrong or the stdlib/minitest
    # assertions if you prefer.
    config.expect_with :rspec do |expectations|
      # Enable only the newer, non-monkey-patching expect syntax.
      # For more details, see:
      #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
      expectations.syntax = [:should, :expect]
    end

    # rspec-mocks config goes here. You can use an alternate test double
    # library (such as bogus or mocha) by changing the `mock_with` option here.
    config.mock_with :rspec do |mocks|
      # Enable only the newer, non-monkey-patching expect syntax.
      # For more details, see:
      #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
      mocks.syntax = :expect

      # Prevents you from mocking or stubbing a method that does not exist on
      # a real object. This is generally recommended.
      mocks.verify_partial_doubles = true
    end

    config.include FactoryGirl::Syntax::Methods if defined? FactoryGirl

    config.use_transactional_fixtures = false

    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
    end

    config.before(:each) do
      DatabaseCleaner.strategy = :transaction
    end

    config.before(:each) do |x|
      puts "            RUNNING #{x.full_description}"
    end

    config.before(:each, :js => true) do
      DatabaseCleaner.strategy = :truncation
    end

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do
      # Clear session data
      Capybara.reset_sessions!
      # Rollback transaction
      DatabaseCleaner.clean
    end

    config.after(:all, :js => true) do
      #size_window(:default)
    end

    config.after(:each, :js => true) do
      #sleep(3)
    end if ENV['DRIVER'] == 'ff'

    config.include Capybara::DSL

    Capybara.register_driver :chrome do |app|
      #caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {"excludeSwitches" => [ "ignore-certificate-errors" ]})
      caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {"args" => [ "--window-size=200,200" ]})
      Capybara::Selenium::Driver.new(app, :browser => :chrome, :desired_capabilities => caps)
    end

    options = {js_errors: false,
               timeout: 180,
               phantomjs_logger: StringIO.new,
               logger: StringIO.new,
               inspector: true,
               phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes']}
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, options)
    end

    class Selenium::WebDriver::Firefox::Profile

      def self.firebug_version
        @firebug_version ||= '2.0.13-fx'
      end

      def self.firebug_version=(version)
        @firebug_version = version
      end

      def frame_position
        @frame_position ||= 'bottom'
      end

      def frame_position=(position)
        @frame_position = ["left", "right", "top", "detached"].detect do |side|
          position && position[0].downcase == side[0]
        end || "bottom"
      end

      def enable_firebug(version = nil)
        version ||= Selenium::WebDriver::Firefox::Profile.firebug_version
        add_extension(File.expand_path("../bin/firebug-#{version}.xpi", __FILE__))

        # For some reason, Firebug seems to trigger the Firefox plugin check
        # (navigating to https://www.mozilla.org/en-US/plugincheck/ at startup).
        # This prevents it. See http://code.google.com/p/selenium/issues/detail?id=4619.
        self["extensions.blocklist.enabled"] = false

        # Prevent "Welcome!" tab
        self["extensions.firebug.showFirstRunPage"] = false

        # Enable for all sites.
        self["extensions.firebug.allPagesActivation"] = "on"

        # Enable all features.
        ['console', 'net', 'script'].each do |feature|
          self["extensions.firebug.#{feature}.enableSites"] = true
        end

        # Closed by default, will open detached.
        self["extensions.firebug.framePosition"] = frame_position
        self["extensions.firebug.previousPlacement"] = 3

        # Disable native "Inspect Element" menu item.
        self["devtools.inspector.enabled"] = false
        self["extensions.firebug.hideDefaultInspector"] = true
      end
    end

    Capybara.register_driver :selenium_with_firebug do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.frame_position = ENV['DRIVER'] && ENV['DRIVER'][2]
      profile.enable_firebug
      Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
    end

    Capybara.javascript_driver = :poltergeist

    Capybara.default_max_wait_time = 2.seconds

    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(app, :browser => :chrome)
    end

    if ENV['DRIVER'] =~ /^pg/
      Capybara.javascript_driver = :poltergeist
    elsif ENV['DRIVER'] == 'chrome'
      Capybara.javascript_driver = :chrome
    else
      Capybara.javascript_driver = :selenium_with_firebug
    end

    config.include ComponentTestHelpers

  end

  FactoryGirl.define do

    sequence :seq_number do |n|
      " #{n}"
    end

  end if defined? FactoryGirl

end
