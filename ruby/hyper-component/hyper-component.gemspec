# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)
require 'hyperstack/component/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-component'
  spec.version       = Hyperstack::Component::VERSION

  spec.authors       = ['David Chang', 'Adam Jahn', 'Mitch VanDuyn', 'Jan Biedermann', 'Adam Creekroad']
  spec.email         = ['mitch@catprint.com']
  spec.homepage      = 'http://ruby-hyperloop.org'
  spec.summary       = 'Opal Ruby wrapper of React.js library.'
  spec.license       = 'MIT'
  spec.description   = 'Write React UI components in pure Ruby.'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperloop.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperloop/hyper-component'
  # }

  spec.files         = `git ls-files`.split("\n").reject { |f| f.match(%r{^(gemfiles|spec)/}) }
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ['lib']

  spec.add_dependency 'hyper-state', Hyperstack::Component::VERSION
  spec.add_dependency 'hyperstack-config', Hyperstack::Component::VERSION
  spec.add_dependency 'libv8', '~> 6.7.0'
  spec.add_dependency 'mini_racer', '~> 0.2.4'
  spec.add_dependency 'opal', '>= 0.11.0', '< 0.12.0'
  spec.add_dependency 'opal-activesupport', '~> 0.3.1'
  spec.add_dependency 'react-rails', '>= 2.4.0', '< 2.7.0'

  spec.add_development_dependency 'bundler', ['>= 1.17.3', '< 2.1']
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'hyper-spec', Hyperstack::Component::VERSION
  spec.add_development_dependency 'jquery-rails'
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'mime-types'
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency 'opal-jquery'
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'opal-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rails-controller-testing'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'sqlite3', '~> 1.3.6' # see https://github.com/rails/rails/issues/35153
  spec.add_development_dependency 'timecop', '~> 0.8.1'
end
