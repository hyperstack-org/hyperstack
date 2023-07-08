# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperstack/state/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-state'
  spec.version       = Hyperstack::State::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Adam Creekroad', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = 'Flux Stores and more for Hyperloop'
  spec.homepage      = 'http://ruby-hyperstack.org'
  spec.metadata      = { 'documentation_uri' => 'https://docs.hyperstack.org/' }
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(gemfiles|spec)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'hyperstack-config', Hyperstack::State::VERSION

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'hyper-component', Hyperstack::State::VERSION
  spec.add_development_dependency 'hyper-spec', Hyperstack::State::VERSION
  spec.add_development_dependency 'listen'
  # spec.add_development_dependency 'mini_racer'#, '< 0.4.0' # something is busted with 0.4.0 and its libv8-node dependency, '~> 0.2.4'
  # spec.add_development_dependency 'opal-browser', '~> 0.2.0'
  spec.add_development_dependency 'opal-rails'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'puma', '<= 5.4.0'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION'] || '>= 5.0.0', '< 7.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'react-rails', '>= 2.4.0', '< 2.7.0'
  spec.add_development_dependency 'rspec', '~> 3.7.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'rubocop' #, '~> 0.51.0'
  spec.add_development_dependency 'sqlite3', '~> 1.4.2' # see https://github.com/rails/rails/issues/35153
  spec.add_development_dependency 'timecop'#, '~> 0.8.1'
end
