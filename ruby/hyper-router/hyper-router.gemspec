# coding: utf-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'hyperstack/router/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-router'
  spec.version       = HyperRouter::VERSION
  spec.authors       = ['Adam George', 'Jan Biedermann']
  spec.email         = ['adamgeorge.31@gmail.com', 'jan@kursator.com']
  spec.homepage      = 'http://ruby-hyperstack.org'
  spec.metadata      = { 'documentation_uri' => 'https://docs.hyperstack.org/' }
  spec.license       = 'MIT'
  spec.summary       = 'hyper-router for Opal, part of the hyperstack framework'

  spec.description   = 'Adds the ability to write and use the react-router in Ruby through Opal'
  spec.files = Dir['{lib}/**/*'] + ['Rakefile']

  spec.add_dependency 'hyper-component', HyperRouter::VERSION
  spec.add_dependency 'hyper-state', HyperRouter::VERSION
  spec.add_dependency 'opal-browser', '>= 0.2.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'hyper-spec', HyperRouter::VERSION
  spec.add_development_dependency 'hyper-store', HyperRouter::VERSION
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'mini_racer'#, '< 0.4.0' # something is busted with 0.4.0 and its libv8-node dependency
  spec.add_development_dependency 'opal-rails', '>= 0.9.4', '< 2.0.0'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION'] || '>= 5.0.0', '< 7.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-collection_matchers'
  spec.add_development_dependency 'rspec-expectations'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'shoulda'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'sqlite3', '~> 1.4.2' # see https://github.com/rails/rails/issues/35153
  spec.add_development_dependency 'timecop'#, '~> 0.8.1'
end
