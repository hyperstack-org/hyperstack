require 'pry'
require 'opal-browser'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'hyper-spec'
require 'hyper-i18n'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.before(:all) do
    `rm -rf spec/test_app/tmp/cache/`
  end
end
