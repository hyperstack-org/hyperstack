# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperloop/version'

Gem::Specification.new do |spec|
  spec.name        = 'hyperloop'
  spec.version     = Hyperloop::VERSION
  spec.summary     = 'Hyperloop stack and generators for Rails'
  spec.description = 'This gem provide the full hyperloop stack for rails plus generators for Hyperloop elements'
  spec.authors     = ['Loic Boutet', 'Adam George', 'Mitch VanDuyn', 'Jan Biedermann']
  spec.email       = ['loic@boutet.com', 'jan@kursator.com']
  spec.homepage    = 'http://ruby-hyperloop.org'
  spec.license     = 'MIT'
  # spec.metadata = {
  #   "homepage_uri" => 'http://ruby-hyperloop.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperloop/hyper-component'
  # }
  spec.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(tasks)/}) }
  spec.require_paths = ['lib']

  # temporarily moved to installer until opal-jquery version issue is fixed
  # spec.add_dependency 'hyper-model', Hyperloop::VERSION
  # spec.add_dependency 'hyper-router', Hyperloop::ROUTERVERSION
  # spec.add_dependency 'opal-rails', '~> 0.9.4'
  # spec.add_dependency 'opal-jquery'

  spec.add_dependency 'hyperloop-config', Hyperloop::VERSION
  spec.add_dependency 'opal-browser', '~> 0.2.0'
  spec.add_dependency 'react-rails', '>= 2.4.0', '< 2.5.0'
  spec.add_dependency 'mini_racer', '~> 0.1.15'
  # https://github.com/discourse/mini_racer/issues/92
  spec.add_dependency 'libv8', '~> 6.3.0'
  spec.add_runtime_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'geminabox', '>= 0.13.11'
end
