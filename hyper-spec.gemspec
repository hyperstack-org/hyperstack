# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-spec/version'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name          = 'hyper-spec'
  spec.version       = HyperSpec::VERSION
  spec.authors       = ['catmando', 'adamcreekroad']
  spec.email         = ['mitch@catprint.com']

  spec.summary       =
    'Drive your Hyperloop client and server specs from RSpec and Capybara'
  spec.description   =
    'A Hyperloop application consists of isomorphic React Components, '\
    'Active Record Models, Stores, Operations and Policiespec. '\
    'Test them all from Rspec, regardless if the code runs on the client or server.'
  spec.homepage      = 'https://github.com/ruby-hyperloop/hyper-spec'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGemspec.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files         =
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Test app dependencies
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'hyper-react', '>= 0.10.0'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'react-rails', '>= 2.3.0'

  # Keep linter-rubocop happy
  spec.add_development_dependency 'rubocop'

  if RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'therubyrhino'
  else
    spec.add_development_dependency 'therubyracer'

    # Actual dependencies
    spec.add_dependency 'capybara'
    spec.add_dependency 'opal'
    spec.add_dependency 'parser'
    spec.add_dependency 'poltergeist'
    spec.add_dependency 'pry'
    spec.add_dependency 'rspec-rails'
    spec.add_dependency 'selenium-webdriver', '~> 3.5.0'
    spec.add_dependency 'timecop', '~> 0.8.1'
    spec.add_dependency 'unparser'
    spec.add_dependency 'webdrivers'

    # Test app dependencies
    spec.add_development_dependency 'chromedriver-helper'
    spec.add_development_dependency 'method_source'
    spec.add_development_dependency 'opal-browser'
    spec.add_development_dependency 'opal-rails'
    spec.add_development_dependency 'puma'
    spec.add_development_dependency 'rspec-collection_matchers'
    spec.add_development_dependency 'rspec-expectations'
    spec.add_development_dependency 'rspec-its'
    spec.add_development_dependency 'rspec-mocks'
    spec.add_development_dependency 'rspec-steps'
    spec.add_development_dependency 'shoulda'
    spec.add_development_dependency 'shoulda-matchers'
    spec.add_development_dependency 'spring-commands-rspec'
  end
end
