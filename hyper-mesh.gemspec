# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)
require 'hypermesh/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-mesh'
  spec.version       = Hypermesh::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = 'React based CRUD access and Synchronization of active record models across multiple clients'
  spec.description   = 'HyperMesh is the base for HyperModel. HyperModel gives your HyperComponents CRUD access to your '\
                       'ActiveRecord models on the client, using the the standard ActiveRecord '\
                       'API. HyperModel also implements push notifications (via a number of '\
                       'possible technologies) so changes to records on the server are '\
                       'dynamically updated on all authorised clients.'
  spec.homepage      = 'http://ruby-hyperloop.org'
  spec.license       = 'MIT'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperloop.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperloop/hyper-component'
  # }

  spec.files          = `git ls-files`.split("\n").reject { |f| f.match(%r{^(examples|gemfiles|pkg|reactive_record_test_app|spec)/}) }
  # spec.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.test_files     = `git ls-files -- {spec}/*`.split("\n")
  spec.require_paths  = ['lib']

  spec.add_dependency 'activerecord', '>= 4.0.0'
  spec.add_dependency 'hyper-component', Hypermesh::VERSION
  spec.add_dependency 'hyper-operation', Hypermesh::VERSION
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'hyper-spec', Hypermesh::VERSION
  spec.add_development_dependency 'hyper-trace'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'opal-activesupport', '~> 0.3.1'
  spec.add_development_dependency 'opal-browser', '~> 0.2.0'
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'parser'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'pusher'
  spec.add_development_dependency 'pusher-fake'
  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'react-rails', '>= 2.4.0', '< 2.5.0'
  spec.add_development_dependency 'reactrb-rails-generator'
  spec.add_development_dependency 'rspec-collection_matchers'
  spec.add_development_dependency 'rspec-expectations'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'rspec-wait'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'shoulda'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'spring-commands-rspec'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'mini_racer', '~> 0.1.15'
  spec.add_development_dependency 'timecop', '~> 0.8.1'
  spec.add_development_dependency 'unparser'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-rescue'
end
