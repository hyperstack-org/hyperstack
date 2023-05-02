ENV["RAILS_ENV"] ||= 'test'

require 'hyper-spec'
require 'pry'
require 'opal-browser'


begin
  require File.expand_path('../test_app/config/environment', __FILE__)
rescue LoadError
  puts 'Could not load test application. Please ensure you have run `bundle exec rake test_app`'
end
require 'rspec/rails'
require 'timecop'
require "rspec/wait"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|

  if config.formatters.empty?
    module Hyperstack
      def self.log_import(s)
        # turn off import logging unless in verbose mode
      end
    end
  end

  config.before :suite do
    # grab the prerendered .js file, for debugging purposes
    class MiniRacer::Context
      alias original_eval eval
      def eval(str, options = nil)
        original_eval str, options
      rescue Exception => e
        File.write('react_prerendering_src.js', str) rescue nil
        raise e
      end
    end
    MiniRacer_Backup = MiniRacer
    Object.send(:remove_const, :MiniRacer)
  end

  config.around(:each, :prerendering_on) do |example|
    MiniRacer = MiniRacer_Backup
    example.run
    Object.send(:remove_const, :MiniRacer)
  end

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

  config.after :each do
    Rails.cache.clear
  end

  config.after(:each) do |example|
    unless example.exception
      #Object.send(:remove_const, :Application) rescue nil
      ObjectSpace.each_object(Class).each do |klass|
        if klass < Hyperstack::Regulation
          klass.instance_variables.each { |v| klass.instance_variable_set(v, nil) }
        end
      end
      PusherFake::Channel.reset if defined? PusherFake
    end
  end

  config.filter_run_including focus: true
  config.filter_run_excluding opal: true
  config.run_all_when_everything_filtered = true
end

FACTORY_BOT = false

#require 'rails_helper'
require 'rspec'
require 'rspec/expectations'
begin
  require 'factory_bot_rails'
rescue LoadError
end
require 'shoulda/matchers'
require 'database_cleaner'
require 'capybara/rspec'
require 'capybara/rails'
# require 'support/component_helpers'
require 'selenium-webdriver'

def policy_allows_all
  stub_const 'TestApplication', Class.new
  stub_const 'TestApplicationPolicy', Class.new
  TestApplicationPolicy.class_eval do
    always_allow_connection
    regulate_all_broadcasts { |policy| policy.send_all }
    allow_change(to: :all, on: [:create, :update, :destroy]) { true }
  end
end


module React
  module IsomorphicHelpers
    def self.xxxload_context(ctx, controller, name = nil)
      @context = Context.new("#{controller.object_id}-#{Time.now.to_i}", ctx, controller, name)
    end
  end
end

#Capybara.default_max_wait_time = 4.seconds

Capybara.server = :puma

# The following is deprecated and replaced by the above... just make sure it works
# before removing
# Capybara.server { |app, port|
#   require 'puma'
#   Puma::Server.new(app).tap do |s|
#     s.add_tcp_listener Capybara.server_host, port
#   end.run.join
# }

module WaitForAjax

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      begin
        sleep 0.25
      end until finished_all_ajax_requests?
    end
  end

  def running?
    jscode = <<-CODE
    (function() {
      if (typeof Opal !== "undefined" && Opal.Hyperstack !== undefined) {
        try {
          return Opal.Hyperstack.$const_get("HTTP")["$active?"]();
        } catch(err) {
          if (typeof jQuery !== "undefined" && jQuery.active !== undefined) {
            return jQuery.active > 0;
          }
        }
      } else if (typeof jQuery !== "undefined" && jQuery.active !== undefined) {
        return jQuery.active > 0;
      } else {
        return false;
      }
    })();
    CODE
    page.evaluate_script(jscode)
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
    e.message == "jQuery or Hyperstack::HTTP is not defined"
  end

end

module CheckErrors
  def check_errors
    logs = page.driver.browser.logs.get(:browser)
    errors = logs.select { |e| e.level == "SEVERE" && e.message.present? }
                .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
    puts "WARNING - FOUND UNEXPECTED ERRORS #{errors}" if errors.present?
  end
end

RSpec.configure do |config|
  config.include WaitForAjax
  config.include CheckErrors
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

  config.include FactoryBot::Syntax::Methods if defined? FactoryBot

  config.use_transactional_fixtures = false

  Capybara.default_max_wait_time = 10.seconds

  config.before(:suite) do
    #DatabaseCleaner.clean_with(:truncation)
    Hyperstack.configuration do |config|
      config.transport = :simple_poller
    end
  end

  # config.before(:each) do
  #   DatabaseCleaner.strategy = :transaction
  # end

  config.before(:each) do |x|
    Hyperstack.class_eval do
      def self.on_server?
        true
      end
    end
  end

  config.before(:each) do |ex|
    class ActiveRecord::Base
      regulate_scope :unscoped
    end
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, :js => true) do
    size_window
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do |example|
    # I am assuming the unless was there just to aid in debug when using pry.rescue
    # perhaps it could be on a switch detecting presence of pry.rescue?
    #unless example.exception
      # Clear session data
      Capybara.reset_sessions!
      # Rollback transaction
      DatabaseCleaner.clean
    #end
  end

  config.after(:all, :js => true) do
    #size_window(:default)
  end

  config.before(:all) do
    # reset this variable so if any specs are setting up models locally
    # the correct hash gets sent to the client.
    ActiveRecord::Base.instance_variable_set('@public_columns_hash', nil)
    class ActiveRecord::Base
      class << self
        alias original_public_columns_hash public_columns_hash
      end
    end
    module Hyperstack
      def self.on_error(_operation, _err, _params, formatted_error_message)
        ::Rails.logger.debug(
          "#{formatted_error_message}\n\n" +
          Pastel.new.red(
            'To further investigate you may want to add a debugging '\
            'breakpoint to the on_error method in config/initializers/hyperstack.rb'
          )
        )
      end
    end
  end

  config.after(:all) do
    class ActiveRecord::Base
      class << self
        alias public_columns_hash original_public_columns_hash
      end
    end
  end

  config.after(:each, :js => true) do
    page.instance_variable_set("@hyper_spec_mounted", false)
  end

  # Fail tests on JavaScript errors in Chrome Headless
  class JavaScriptError < StandardError; end

  config.after(:each, js: true) do |spec|
    logs = page.driver.browser.logs.get(:browser)
    if spec.exception
      all_messages = logs.select { |e| e.message.present? }
                         .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
      puts "Javascript client console messages:\n\n" +
           all_messages.join("\n\n") if all_messages.present?
    end
    errors = logs.select { |e| e.level == "SEVERE" && e.message.present? }
                .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
    if client_options[:deprecation_warnings] == :on
      warnings = logs.select { |e| e.level == "WARNING" && e.message.present? }
                  .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
      puts "\033[0;33;1m\nJavascript client console warnings:\n\n" + warnings.join("\n\n") + "\033[0;30;21m" if warnings.present?
    end
    if client_options[:raise_on_js_errors] == :show && errors.present?
      puts "\033[031m\nJavascript client console errors:\n\n" + errors.join("\n\n") + "\033[0;30;21m"
    elsif client_options[:raise_on_js_errors] == :debug && errors.present?
      binding.pry
    elsif client_options[:raise_on_js_errors] != :off && errors.present?
      raise JavaScriptError, errors.join("\n\n")
    end
  end

  config.include Capybara::DSL

  # Capybara.register_driver :chrome do |app|
  #   #caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {"excludeSwitches" => [ "ignore-certificate-errors" ]})
  #   caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {"args" => [ "--window-size=200,200" ]})
  #   Capybara::Selenium::Driver.new(app, :browser => :chrome, :desired_capabilities => caps)
  # end

  # Use legacy hyper-spec on_client behavior
  HyperSpec::Helpers.alias_method :on_client, :before_mount
end

FactoryBot.define do

  sequence :seq_number do |n|
    " #{n}"
  end

end if defined? FactoryBot
