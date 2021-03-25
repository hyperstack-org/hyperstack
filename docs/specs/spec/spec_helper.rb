# spec_helper.rb
require 'hyper-spec'
require 'pry'  # optional

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../../../specs/config/environment', __FILE__)

require 'rspec/rails'
