# spec/spec_helper.rb

require "bundler"
Bundler.require
ENV["RACK_ENV"] ||= "test"

require File.join(File.dirname(__FILE__), "..", "app.rb")

require "rspec"
require "rack/test"
require "hyper-spec/rack"

Capybara.app = HyperSpecTestController.wrap(app: app)

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
