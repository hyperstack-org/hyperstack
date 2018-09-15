# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-i18n/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-i18n'
  spec.version       = HyperI18n::VERSION
  spec.authors       = ['adamcreekroad']
  spec.email         = ['adamgeorge.31@gmail.com']

  spec.summary       = 'HyperI18n seamlessly brings Rails I18n into your Hyperloop application.'
  spec.homepage      = 'https://www.github.com/ruby-hyperloop/hyper-i18n'
  spec.license       = 'MIT'

  spec.files          = `git ls-files`.split("\n")
  spec.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths  = ['lib']

  spec.add_dependency 'hyper-operation', HyperI18n::VERSION
  spec.add_dependency 'i18n'

  spec.add_development_dependency 'bundler', '~> 1.16.0'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'hyper-model', HyperI18n::VERSION
  spec.add_development_dependency 'hyper-spec', HyperI18n::VERSION
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'sqlite3'
end
