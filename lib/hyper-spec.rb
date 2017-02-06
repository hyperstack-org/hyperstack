require "hyper-spec/version"
require "hyper-spec/engine"

require 'opal'

require 'hyper-spec/component_helpers'

# DELETE require 'pry'
# DELETE begin
# DELETE   require File.expand_path('../test_app/config/environment', __FILE__)
# DELETE rescue LoadError
# DELETE   puts 'Could not load test application. Please ensure you have run `bundle exec rake test_app`'
# DELETE end
# DELETE require 'rspec/rails'
# DELETE require 'timecop'
# DELETE require "rspec/wait"
# DELETE #require 'pusher-fake/support/base'

# DELETE Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # DELETE config.color = true
  # DELETE config.fail_fast = ENV['FAIL_FAST'] || false
  # DELETE config.fixture_path = File.join(File.expand_path(File.dirname(__FILE__)), "fixtures")
  # DELETE config.infer_spec_type_from_file_location!
  config.mock_with :rspec
  # DELETE config.raise_errors_for_deprecations!

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  # DELETE config.use_transactional_fixtures = true

  # config.after :each do
  #   Rails.cache.clear
  # end

  config.after(:each) do |example|
    unless example.exception
      # DELETE #Object.send(:remove_const, :Application) rescue nil
      # DELETE ObjectSpace.each_object(Class).each do |klass|
      # DELETE   if klass < HyperMesh::Regulation
      # DELETE     klass.instance_variables.each { |v| klass.instance_variable_set(v, nil) }
      # DELETE   end
      # DELETE end
      PusherFake::Channel.reset if defined? PusherFake
    end
  end

  # DELETE config.filter_run_including focus: true
  # DELETE config.filter_run_excluding opal: true
  # DELETE config.run_all_when_everything_filtered = true
end

# DELETE FACTORY_GIRL = false

# DELETE #require 'rails_helper'
# DELETE require 'rspec'
# DELETE require 'rspec/expectations'
# DELETE begin
# DELETE   require 'factory_girl_rails'
# DELETE rescue LoadError
# DELETE end
# DELETE require 'shoulda/matchers'
# DELETE require 'database_cleaner'
require 'capybara/rspec'
#hmmm.... where should this go???? require 'capybara/rails'
require 'capybara/poltergeist'
require 'selenium-webdriver'

module React
  module IsomorphicHelpers
    def self.load_context(ctx, controller, name = nil)
      @context = Context.new("#{controller.object_id}-#{Time.now.to_i}", ctx, controller, name)
    end
  end
end

# DELETE #Capybara.default_max_wait_time = 4.seconds

Capybara.server = :puma

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
    puts "wait_for_ajax failed while testing state of jQuery.active: #{e}"
  end

  def finished_all_ajax_requests?
    unless running?
      sleep 0.25 # this was 1 second, not sure if its necessary to be so long...
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

  Capybara.default_max_wait_time = 10

  config.before(:each) do |x|
    HyperMesh.class_eval do
      def self.on_server?
        true
      end
    end
  end if defined? HyperMesh

  config.before(:each, :js => true) do
    size_window
  end

  config.after(:each, :js => true) do
    page.instance_variable_set("@hyper_spec_mounted", false)
  end


  if false # delete? THIS BLOCK ????
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

    config.before(:each, :js => true) do
      DatabaseCleaner.strategy = :truncation
    end

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do |example|
      unless example.exception
        # Clear session data
        Capybara.reset_sessions!
        # Rollback transaction
        DatabaseCleaner.clean
      end
    end
  end


  config.include Capybara::DSL

  Capybara.register_driver :chrome do |app|
    #caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {"excludeSwitches" => [ "ignore-certificate-errors" ]})
    caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {"args" => [ "--window-size=200,200" ]})
    Capybara::Selenium::Driver.new(app, :browser => :chrome, :desired_capabilities => caps)
  end

  options = {
    js_errors: false,
    timeout: 180,
    inspector: true,
    phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes']
  }
  options.merge!({phantomjs_logger: StringIO.new, logger: StringIO.new,}) unless ENV['SHOW_LOGS']
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
      @frame_position ||= 'detached'
    end

    def frame_position=(position)
      @frame_position = ["left", "right", "top", "detached"].detect do |side|
        position && position[0].downcase == side[0]
      end || "detached"
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
      self["extensions.firebug.defaultPanelName"] = "console"

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

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end

  if ENV['DRIVER'] =~ /^ff/
    Capybara.javascript_driver = :selenium_with_firebug
  elsif ENV['DRIVER'] == 'chrome'
    Capybara.javascript_driver = :chrome
  else
    Capybara.javascript_driver = :poltergeist
  end

  include ComponentTestHelpers

end
