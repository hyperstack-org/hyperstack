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

  spec.add_dependency 'i18n'
  spec.add_dependency 'hyper-component'
  spec.add_dependency 'hyper-operation'
  spec.add_dependency 'hyper-store'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop'
end
