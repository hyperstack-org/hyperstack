require 'pry'
require 'opal-browser'
require 'database_cleaner'

ENV['RAILS_ENV'] ||= 'development'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'hyper-spec'
require 'rails-hyperstack'
require 'puma'
require 'turbolinks'

Capybara.server = :puma

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.before(:all) do
    `rm -rf spec/test_app/tmp/cache/`
  end
  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
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
