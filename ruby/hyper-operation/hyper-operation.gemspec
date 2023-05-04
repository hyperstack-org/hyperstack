# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-operation/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-operation'
  spec.version       = Hyperstack::Operation::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = 'HyperOperations are the swiss army knife of the Hyperstack'
  spec.homepage      = 'http://ruby-hyperstack.org'
  spec.metadata      = { 'documentation_uri' => 'https://docs.hyperstack.org/' }
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject { |f| f.match(%r{^(gemfiles|examples|spec)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 4.0.0'
  spec.add_dependency 'hyper-component', Hyperstack::Operation::VERSION
  spec.add_dependency 'mutations'
  spec.add_dependency 'opal-activesupport', '~> 0.3.1'
  spec.add_dependency 'tty-table'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'hyper-spec', Hyperstack::Operation::VERSION
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'opal-browser', '~> 0.2.0'
  spec.add_development_dependency 'opal-rails', '>= 0.9.4', '< 2.0'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'puma', '<= 5.4.0'
  spec.add_development_dependency 'pusher'
  spec.add_development_dependency 'pusher-fake'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION'] || '>= 5.0.0', '< 7.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'react-rails', '>= 2.4.0', '< 2.7.0'
  spec.add_development_dependency 'redis'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'rspec-wait'
  spec.add_development_dependency 'sqlite3', '~> 1.4.2' # see https://github.com/rails/rails/issues/35153
  spec.add_development_dependency 'timecop', '~> 0.8.1'
end
