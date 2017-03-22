# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-spec/version'

Gem::Specification.new do |spec|
  spec.name          = "hyper-spec"
  spec.version       = HyperSpec::VERSION
  spec.authors       = ["catmando"]
  spec.email         = ["mitch@catprint.com"]

  spec.summary       = "Drive your Hyperloop client and server specs from RSpec and Capybara"
  spec.description   = "A Hyperloop application consists of isomorphic React Components, Active Record Models, Stores, Operations and Policiespec. "\
                       "Test them all from Rspec, regardless if the code runs on the client or server."
  spec.homepage      = "https://github.com/ruby-hyperloop/hyper-spec"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'hyper-react', '>= 0.10.0'

  spec.add_development_dependency 'rspec-rails'

  # For Test Rails App
  spec.add_development_dependency 'rails', '~>5.0.0' #'4.2.4'
  spec.add_development_dependency 'react-rails', '~> 1.4.0'
  spec.add_development_dependency 'opal-rails'
  # spec.add_development_dependency 'opal-activesupport'
  # spec.add_development_dependency 'factory_girl_rails'
  # spec.add_development_dependency 'reactrb-rails-generator'
  # spec.add_development_dependency 'rspec-wait'
  spec.add_development_dependency 'puma'

  if RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'therubyrhino'
  else
    spec.add_development_dependency 'therubyracer', '0.12.2'

    # The following allow react code to be tested from the server side
    spec.add_development_dependency 'rspec-mocks'
    spec.add_development_dependency 'rspec-expectations'

    # spec.add_development_dependency 'factory_girl_rails'
    spec.add_development_dependency 'shoulda'
    spec.add_development_dependency 'shoulda-matchers'
    spec.add_development_dependency 'rspec-its'
    spec.add_development_dependency 'rspec-collection_matchers'
    spec.add_development_dependency 'capybara'
    spec.add_development_dependency 'selenium-webdriver', '2.53.4'
    spec.add_development_dependency 'poltergeist'
    spec.add_development_dependency 'spring-commands-rspec'
    spec.add_development_dependency 'chromedriver-helper'
    spec.add_development_dependency 'parser'
    spec.add_development_dependency 'unparser',  '0.2.5'
    spec.add_development_dependency 'pry'
    spec.add_development_dependency 'method_source'
    spec.add_development_dependency 'opal-browser'
    spec.add_development_dependency 'rspec-steps'
    spec.add_dependency "rails"
    spec.add_development_dependency 'timecop'
  end
end
