# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-spec/version'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name          = 'hyper-spec'
  spec.version       = HyperSpec::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Adam Creekroad', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = 'Drive your Hyperloop client and server specs from RSpec and Capybara'
  spec.description   = 'A Hyperloop application consists of isomorphic React Components, '\
                       'Active Record Models, Stores, Operations and Policiespec. '\
                       'Test them all from Rspec, regardless if the code runs on the client or server.'
  spec.homepage      = 'http://ruby-hyperloop.org'
  spec.license       = 'MIT'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperloop.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperloop/hyper-component'
  # }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(gemfiles|spec)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'capybara'
  spec.add_dependency 'chromedriver-helper', '1.2.0'
  spec.add_dependency 'libv8', '~> 6.3.0' # see https://github.com/discourse/mini_racer/issues/92
  spec.add_dependency 'method_source'
  spec.add_dependency 'mini_racer', '~> 0.2.4'
  spec.add_dependency 'opal', '>= 0.11.0', '< 0.12.0'
  spec.add_dependency 'parser', '>= 2.3.3.1'
  spec.add_dependency 'pry'
  spec.add_dependency 'rspec-rails'
  spec.add_dependency 'selenium-webdriver'
  spec.add_dependency 'timecop', '~> 0.8.1'
  spec.add_dependency 'uglifier'
  spec.add_dependency 'unparser'
  spec.add_dependency 'webdrivers'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'hyper-component', HyperSpec::VERSION
  spec.add_development_dependency 'opal-browser', '~> 0.2.0'
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'react-rails', '>= 2.3.0', '< 2.5.0'
  spec.add_development_dependency 'rspec-collection_matchers'
  spec.add_development_dependency 'rspec-expectations'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'shoulda'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'spring-commands-rspec'
end
