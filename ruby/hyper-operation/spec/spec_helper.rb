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
require 'rspec-steps'
require 'hyper-operation'

require "rspec/wait"
require 'database_cleaner'

Capybara.server = :puma

RSpec.configure do |config|

  if config.formatters.empty?
    module Hyperstack
      def self.log_import(s)
        # turn off import logging unless in verbose mode
      end
    end
  end

  config.after :each do
    Rails.cache.clear
  end

  config.after(:each) do |example|
    unless example.exception
      #Object.send(:remove_const, :Application) rescue nil
      ObjectSpace.each_object(Class).each do |klass|
        if klass < Hyperstack::Regulation || klass < Hyperstack::Operation
          klass.instance_variables.each { |v| klass.instance_variable_set(v, nil) }
        end
      end
      PusherFake::Channel.reset if defined? PusherFake
    end
  end

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
    #mocks.verify_partial_doubles = true
  end

  config.include FactoryBot::Syntax::Methods if defined? FactoryBot

  config.use_transactional_fixtures = true # -sfc george false

  Capybara.default_max_wait_time = 10.seconds

  config.before(:suite) do
    #Hyperstack.define_setting :connect_session, false
    # -sfc george DatabaseCleaner.clean_with(:truncation)
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
    # Hyperstack.configuration do |config|
    #   config.connect_session = false
    # end
  end

  config.before(:each) do
    if Hyperstack.connection[:adapter] == :redis
      Hyperstack::Connection.adapter::RedisRecord::Base.client.flushdb
    end
  end

  config.before(:each, :js => true) do
    # -sfc george DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, :js => true) do
    size_window
  end

  # config.before(:each) do
  #   DatabaseCleaner.start
  # end

  config.after(:each) do |example|
    unless example.exception
      # Clear session data
      Capybara.reset_sessions!
      # Rollback transaction
      # -sfc george DatabaseCleaner.clean
    end
  end

  # Fail tests on JavaScript errors in Chrome Headless
  # class JavaScriptError < StandardError; end

  # config.after(:each, js: true) do |spec|
  #   errors = page.driver.browser.manage.logs.get(:browser)
  #               .select { |e| e.level == "SEVERE" && e.message.present? }
  #               #.map { |m| m.message.gsub(/\\n/, "\n") }.to_a
  #               #.reject { |e| e =~ /Unexpected response code: 200/ }
  #   raise JavaScriptError, errors.join("\n\n") if errors.present?
  # end

  # Use legacy hyper-spec on_client behavior
  HyperSpec::ComponentTestHelpers.alias_method :on_client, :before_mount
end

module HyperSpec
  module ComponentTestHelpers
    alias old_expect_promise expect_promise
    def expect_promise(str_or_promise = nil, &block)
      if str_or_promise.is_a? Promise
        result = nil
        str_or_promise.then { |*args| result = args }
        loop do
          return expect(result.count == 1 ? result.first : result) if str_or_promise.resolved?
          sleep 0.25
        end
      else
        old_expect_promise(str_or_promise, &block)
      end
    end
  end
end

RSpec::Matchers.define :have_failed_with do |expected|
  match do |promise|
    the_exception = !expected
    promise.fail { |exception| the_exception = exception }
    if expected < Exception
      expected == the_exception.class
    else
      the_exception == expected
    end
  end
end

RSpec::Matchers.define :have_succeeded_with do |*expected|
  match do |promise|
    the_results = nil
    promise.then { |*results| the_results = results }
    the_results == expected
  end
end
