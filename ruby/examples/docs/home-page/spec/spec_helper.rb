require 'hyper-spec'
require 'pry'
require 'opal-browser'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)

require 'rspec/rails'
require 'timecop'
