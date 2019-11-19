# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperstack/config/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyperstack-config'
  spec.version       = Hyperstack::Config::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = %q{Provides a single point configuration module for hyperstack gems}
  spec.homepage      = 'http://ruby-hyperstack.org'
  spec.license       = 'MIT'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperstack.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperstack/hyper-component'
  # }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  #spec.bindir        = 'exe'
  #spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.executables << 'hyperstack-hotloader'
  spec.require_paths = ['lib']

  spec.add_dependency 'listen', '~> 3.0'  # for hot loader
  spec.add_dependency 'mini_racer', '~> 0.2.6'
  spec.add_dependency 'opal', '>= 0.11.0', '< 0.12.0'
  spec.add_dependency 'opal-browser', '~> 0.2.0'
  spec.add_dependency 'uglifier'
  spec.add_dependency 'websocket' # for hot loader


  spec.add_development_dependency 'bundler', ['>= 1.17.3', '< 2.1']
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.7.0'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'sqlite3', '~> 1.3.6' # see https://github.com/rails/rails/issues/35153
  spec.add_development_dependency 'timecop', '~> 0.8.1'
end
