require 'hyper-spec'
require 'pry'
require 'opal-browser'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'rspec-steps'
require 'hyper-operation'

require 'database_cleaner'
require 'factory_bot_rails'
require 'puma'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :truncation
  end
  config.before(:each) do
    DatabaseCleaner.start
  end

  Capybara.server = :puma

  config.before(:each) do
    Hyperloop.class_eval do
      def self.on_server?
        true
      end
    end
  end
end
