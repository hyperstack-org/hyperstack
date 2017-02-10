require 'hyper-spec'
require 'hyper-store'
require 'pry'
require 'opal-browser'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'rspec-steps'
require 'timecop'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
