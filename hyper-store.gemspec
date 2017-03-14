# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-store/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-store'
  spec.version       = HyperStore::VERSION
  spec.authors       = ['catmando', 'adamcreekroad']
  spec.email         = ['mitch@catprint.com']

  spec.summary       = 'Flux Stores and more for Hyperloop'
  spec.homepage      = 'https://ruby-hyperloop.io'
  spec.license       = 'MIT'


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'hyperloop-config', '>= 0.9.2'
  spec.add_development_dependency 'bundler', '~> 1.12'
  #spec.add_development_dependency 'hyper-react', '>= 0.12.0'
  spec.add_development_dependency 'hyper-spec'
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'opal'
  spec.add_development_dependency 'opal-browser'
  spec.add_development_dependency 'opal-rails'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'react-rails', '< 1.10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-steps'
  spec.add_development_dependency 'sqlite3'

  # Keep linter-rubocop happy
  spec.add_development_dependency 'rubocop'
end
