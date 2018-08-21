require 'hyper-spec'
require 'pry'
require 'opal-browser'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'rspec-steps'
require 'hyper-router'

#require "rspec/wait"
#require 'database_cleaner'

#Capybara.server = :puma

RSpec.configure do |config|

  config.after :each do
    Rails.cache.clear
  end

  # config.after(:each) do |example|
  #   unless example.exception
  #     #Object.send(:remove_const, :Application) rescue nil
  #     ObjectSpace.each_object(Class).each do |klass|
  #       if klass < Hyperstack::Regulation || klass < Hyperstack::Operation
  #         klass.instance_variables.each { |v| klass.instance_variable_set(v, nil) }
  #       end
  #     end
  #     PusherFake::Channel.reset if defined? PusherFake
  #   end
  # end

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

  #config.include FactoryBot::Syntax::Methods if defined? FactoryBot

  #config.use_transactional_fixtures = false

  #Capybara.default_max_wait_time = 10.seconds

  config.before(:suite) do
    #DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    #DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do |x|
    # Hyperstack.class_eval do
    #   def self.on_server?
    #     true
    #   end
    # end
  end

  config.before(:each, :js => true) do
    #DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, :js => true) do
    size_window
  end

  config.before(:each) do
    #DatabaseCleaner.start
  end

  config.after(:each) do |example|
    unless example.exception
      # Clear session data
      Capybara.reset_sessions!
      # Rollback transaction
      #DatabaseCleaner.clean
    end
  end
end
