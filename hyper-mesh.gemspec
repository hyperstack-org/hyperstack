# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)

require 'hypermesh/version'

Gem::Specification.new do |s|

    s.name          = "hyper-mesh"
    s.version       = Hypermesh::VERSION
    s.authors       = ["Mitch VanDuyn"]
    s.email         = ["mitch@catprint.com"]

    s.summary       = "React based CRUD access and Synchronization of active record models across multiple clients"
    s.description   = "HyperMesh gives your HyperReact components CRUD access to your "\
                      "ActiveRecord models on the client, using the the standard ActiveRecord "\
                      "API. HyperMesh also implements push notifications (via a number of "\
                      "possible technologies) so changes to records on the server are "\
                      "dynamically updated on all authorised clients."
    s.homepage      = "https://github.com/reactive-ruby/hyper-mesh"
    s.license       = "MIT"

    s.files          = `git ls-files`.split("\n")
    s.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
    s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.require_paths  = ['lib']

    s.add_dependency 'activerecord'
    s.add_dependency 'hyper-operation', '>= 0.5.0'
    s.add_dependency 'hyper-component', '>= 0.12.3'

    s.add_development_dependency 'bundler', '~> 1.8'
    s.add_development_dependency 'rake', '~> 10.0'
    s.add_development_dependency 'rspec-rails'
    s.add_development_dependency 'timecop'

    # For Test Rails App
    s.add_development_dependency 'rails'
    s.add_development_dependency 'react-rails'
    s.add_development_dependency 'opal-rails'
    s.add_development_dependency 'opal-activesupport'
    s.add_development_dependency 'factory_girl_rails'
    s.add_development_dependency 'reactrb-rails-generator'
    s.add_development_dependency 'rspec-wait'
    s.add_development_dependency 'puma'

    s.add_development_dependency 'pusher'
    s.add_development_dependency 'pusher-fake'
    s.add_development_dependency 'opal-browser'

    # Keep linter-rubocop happy
    s.add_development_dependency 'rubocop'

    if RUBY_PLATFORM == 'java'
      s.add_development_dependency 'jdbc-sqlite3'
      s.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
      s.add_development_dependency 'therubyrhino'
    else
      s.add_development_dependency 'sqlite3'
      s.add_development_dependency 'mysql2' # for codeship
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
      s.add_development_dependency 'selenium-webdriver', '< 3'
      s.add_development_dependency 'poltergeist'
      s.add_development_dependency 'spring-commands-rspec'
      s.add_development_dependency 'chromedriver-helper'
      s.add_development_dependency 'rspec-steps'
      s.add_development_dependency 'parser'
      s.add_development_dependency 'unparser'
      s.add_development_dependency 'jquery-rails'
      s.add_development_dependency 'pry-byebug'
      s.add_development_dependency 'hyper-spec'
      s.add_development_dependency 'hyper-trace'
    end
end
