require 'rubygems'
gemfile = File.expand_path("../../../../Gemfile", __FILE__)

ENV['BUNDLE_GEMFILE'] = gemfile
require 'bundler'
Bundler.setup
