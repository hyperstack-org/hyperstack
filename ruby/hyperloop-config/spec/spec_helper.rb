require 'pry'

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'hyper-spec'
require 'timecop'

require 'hyperloop-config'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
