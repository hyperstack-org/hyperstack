# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)

require 'synchromesh/version'

Gem::Specification.new do |s|

    s.name          = "synchromesh"
    s.version       = Synchromesh::VERSION
    s.authors       = ["Mitch VanDuyn"]
    s.email         = ["mitch@catprint.com"]

    s.summary       = "Synchronization of active record models across multiple clients using Pusher, ActionCable, or Polling"
    s.description   = "Work in progress"
    s.homepage      = "https://github.com/reactive-ruby/synchromesh"
    s.license       = "MIT"

    s.files          = `git ls-files`.split("\n")
    s.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
    s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.require_paths  = ['lib']
    s.add_dependency 'activerecord', '>= 0.3.0'
    s.add_dependency 'reactive-record', '>= 0.7.43'

    s.add_development_dependency 'bundler', '~> 1.8'
    s.add_development_dependency 'rake', '~> 10.0'
    s.add_development_dependency 'rspec-rails'#, '3.3.3'
    s.add_development_dependency 'timecop'
    #s.add_development_dependency 'opal-rspec'#, '0.4.3'

    # For Test Rails App
    s.add_development_dependency 'rails', '~>5.0.0' #'4.2.4'
    s.add_development_dependency 'react-rails'#, '1.3.1'
    s.add_development_dependency 'opal-rails'#, '0.8.1'
    s.add_development_dependency 'factory_girl_rails'
    s.add_development_dependency 'reactrb-rails-generator'
    s.add_development_dependency 'rspec-wait'
    s.add_development_dependency 'puma'
    #s.add_development_dependency 'thin'

    s.add_development_dependency 'pusher'
    s.add_development_dependency 'pusher-fake'

    if RUBY_PLATFORM == 'java'
      s.add_development_dependency 'jdbc-sqlite3'
      s.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
      s.add_development_dependency 'therubyrhino'
    else
      s.add_development_dependency 'sqlite3', '1.3.10'
      s.add_development_dependency 'mysql2' # for codeship
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
