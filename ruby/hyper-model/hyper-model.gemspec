# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)
require 'hyper_model/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-model'
  spec.version       = HyperModel::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = 'React based CRUD access and Synchronization of active record models across multiple clients'
  spec.description   = 'HyperModel gives your HyperComponents CRUD access to your '\
                       'ActiveRecord models on the client, using the the standard ActiveRecord '\
                       'API. HyperModel also implements push notifications (via a number of '\
                       'possible technologies) so changes to records on the server are '\
                       'dynamically updated on all authorised clients.'
  spec.homepage      = 'http://ruby-hyperstack.org'
  spec.license       = 'MIT'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperstack.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperstack/hyper-component'
  # }

  spec.files          = `git ls-files`.split("\n").reject { |f| f.match(%r{^(examples|gemfiles|pkg|reactive_record_test_app|spec)/}) }
  # spec.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.test_files     = `git ls-files -- {spec}/*`.split("\n")
  spec.require_paths  = ['lib']

  spec.add_dependency 'activemodel'
  spec.add_dependency 'activerecord', '>= 4.0.0'
  spec.add_dependency 'hyper-operation', HyperModel::VERSION

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'hyper-spec', HyperModel::VERSION
  spec.add_development_dependency 'mini_racer'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'opal-rails', '>= 0.9.4', '< 2.0'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'pusher'
  spec.add_development_dependency 'pusher-fake'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION'] || '>= 5.0.0', '< 7.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'react-rails', '>= 2.4.0', '< 2.5.0'
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
  spec.add_development_dependency 'spring-commands-rspec', '~> 1.0.4'
  spec.add_development_dependency 'sqlite3', '~> 1.4.2' # see https://github.com/rails/rails/issues/35153, '~> 1.3.6'
  spec.add_development_dependency 'timecop', '~> 0.8.1'
end
