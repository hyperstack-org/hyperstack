# coding: utf-8

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'hyper-router/version'

Gem::Specification.new do |s|
  s.name          = 'hyper-router'
  s.version       = HyperRouter::VERSION
  s.authors       = ['Adam George']
  s.email         = ['adamgeorge.31@gmail.com']
  s.summary       = 'react-router for Opal, part of the hyperloop gem family'
  s.description   = 'Adds the ability to write and use the react-router in Ruby through Opal'
  s.files = Dir['{lib}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'opal-rails'
  s.add_dependency 'react-rails', '>= 2.3.0'
  s.add_dependency 'hyper-component'
  s.add_dependency 'hyper-react', '~> 0.12.7'
  s.add_dependency 'opal-browser'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'opal-rspec'
  s.add_development_dependency 'sinatra'

  # For Test Rails App
  s.add_development_dependency 'rails'
  s.add_development_dependency 'react-rails'
  s.add_development_dependency 'opal-rails'
  s.add_development_dependency 'hyper-spec'
  s.add_development_dependency 'listen'

  if RUBY_PLATFORM == 'java'
    s.add_development_dependency 'jdbc-sqlite3'
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
    s.add_development_dependency 'therubyrhino'
  else
    s.add_development_dependency 'sqlite3'
    s.add_development_dependency 'therubyracer'

    # The following allow react code to be tested from the server side
    s.add_development_dependency 'rspec-mocks'
    s.add_development_dependency 'rspec-expectations'
    s.add_development_dependency 'pry'
    s.add_development_dependency 'pry-rescue'
    s.add_development_dependency 'pry-stack_explorer'

    # s.add_development_dependency 'factory_girl_rails'
    s.add_development_dependency 'shoulda'
    s.add_development_dependency 'shoulda-matchers'
    s.add_development_dependency 'rspec-its'
    s.add_development_dependency 'rspec-collection_matchers'
    s.add_development_dependency 'database_cleaner'
    s.add_development_dependency 'capybara'
    s.add_development_dependency 'selenium-webdriver', '~> 3.6'
    s.add_development_dependency 'poltergeist'
    s.add_development_dependency 'spring-commands-rspec'
    s.add_development_dependency 'chromedriver-helper'
    s.add_development_dependency 'rspec-steps'
    s.add_development_dependency 'parser'
    s.add_development_dependency 'unparser'
    s.add_development_dependency 'jquery-rails'
  end
end
