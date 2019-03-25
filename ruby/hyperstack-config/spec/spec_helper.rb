require 'pry'

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'timecop'
require 'hyperstack-config'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
