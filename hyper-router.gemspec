# coding: utf-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'hyper-router/version'
if File.exist? '../hyper-component/lib/hyperloop/component/version'
  require '../hyper-component/lib/hyperloop/component/version'
else
  require 'hyperloop/component/version'
end

Gem::Specification.new do |spec|
  spec.name          = 'hyper-router'
  spec.version       = HyperRouter::VERSION
  spec.authors       = ['Adam George', 'Jan Biedermann']
  spec.email         = ['adamgeorge.31@gmail.com', 'jan@kursator.com']
  spec.homepage      = 'http://ruby-hyperloop.org'
  spec.license       = 'MIT'
  spec.summary       = 'hyper-router for Opal, part of ruby-hyperloop'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperloop.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperloop/hyper-component'
  # }

  spec.description   = 'Adds the ability to write and use the react-router in Ruby through Opal'
  spec.files = Dir['{lib}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'hyper-component', Hyperloop::Component::VERSION
  spec.add_dependency 'hyper-react', Hyperloop::Component::VERSION
  spec.add_dependency 'opal-browser', '~> 0.2.0'
  spec.add_dependency 'opal-rails', '~> 0.9.3'
  spec.add_dependency 'react-rails', '>= 2.4.0', '< 2.5.0'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'hyper-spec', Hyperloop::Component::VERSION
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'parser'
  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-collection_matchers'
  spec.add_development_dependency 'rspec-expectations'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'selenium-webdriver'
  spec.add_development_dependency 'shoulda'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'sinatra'
  spec.add_development_dependency 'spring-commands-rspec'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'mini_racer', '~> 0.1.15'
  spec.add_development_dependency 'timecop', '~> 0.8.1'
  spec.add_development_dependency 'unparser'
end
