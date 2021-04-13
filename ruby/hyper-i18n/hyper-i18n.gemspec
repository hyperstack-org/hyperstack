# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperstack/i18n/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-i18n'
  spec.version       = Hyperstack::I18n::VERSION
  spec.authors       = ['adamcreekroad']
  spec.email         = ['adamgeorge.31@gmail.com']

  spec.summary       = 'HyperI18n seamlessly brings Rails I18n into your Hyperstack application.'
  spec.homepage      = 'http://ruby-hyperstack.org'
  spec.documentation = 'https://docs.hyperstack.org/'
  spec.download      = 'https://github.com/hyperstack-org/hyperstack'
  spec.license       = 'MIT'

  spec.files          = `git ls-files`.split("\n")
  spec.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths  = ['lib']

  spec.add_dependency 'hyper-operation', Hyperstack::I18n::VERSION
  spec.add_dependency 'i18n'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'hyper-model', Hyperstack::I18n::VERSION
  spec.add_development_dependency 'hyper-spec', Hyperstack::I18n::VERSION
  spec.add_development_dependency 'mini_racer'
  spec.add_development_dependency 'opal-rails', '>= 0.9.4', '< 2.0.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop' #, '~> 0.51.0'
  spec.add_development_dependency 'sqlite3', '~> 1.4.2' # see https://github.com/rails/rails/issues/35153
end
