# coding: utf-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'react/router/version'

Gem::Specification.new do |s|
  s.name          = 'reactrb-router'
  s.version       = ReactrbRouter::VERSION
  s.authors       = ['Adam George']
  s.email         = ['adamgeorge.31@gmail.com']
  s.summary       = 'react-router for Opal, part of the reactrb gem family'
  s.description   = 'Adds the ability to write and use the react-router in Ruby through Opal'
  s.files = Dir['{lib}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']

  # s.add_dependency 'opal-rails'
  # s.add_dependency 'react-rails'
  s.add_dependency 'hyper-react'
  s.add_dependency 'opal-browser'

  s.add_development_dependency 'bundler', '~> 1.8'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec-rails', '3.3.3'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'opal-rspec'#, '0.4.3'
  s.add_development_dependency 'sinatra'

  # For Test Rails App
  s.add_development_dependency 'rails', '4.2.4'
  s.add_development_dependency 'react-rails', '1.3.1'
  s.add_development_dependency 'opal-rails', '0.8.1'

  if RUBY_PLATFORM == 'java'
    s.add_development_dependency 'jdbc-sqlite3'
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
    s.add_development_dependency 'therubyrhino'
  else
    s.add_development_dependency 'sqlite3', '1.3.10'
    s.add_development_dependency 'therubyracer', '0.12.2'

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
    s.add_development_dependency 'selenium-webdriver'
    s.add_development_dependency 'poltergeist'
    s.add_development_dependency 'spring-commands-rspec'
    s.add_development_dependency 'chromedriver-helper'
    s.add_development_dependency 'rspec-steps'
    s.add_development_dependency 'parser'
    s.add_development_dependency 'unparser'
    s.add_development_dependency 'jquery-rails'
  end
end
