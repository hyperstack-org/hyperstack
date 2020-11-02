# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperloop/console/version'

Gem::Specification.new do |spec|
  spec.name          = "hyper-console"
  spec.version       = Hyperloop::Console::VERSION
  spec.authors       = ["catmando"]
  spec.email         = ["mitch@catprint.com"]

  spec.summary       = %q{IRB style console for Hyperloop applications.}
  spec.homepage      = "http://ruby-hyperloop.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'hyper-operation', Hyperloop::Console::VERSION
  spec.add_dependency 'hyper-store', Hyperloop::Console::VERSION

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency 'hyper-component', Hyperloop::Console::VERSION
  spec.add_development_dependency 'hyper-operation', Hyperloop::Console::VERSION
  spec.add_development_dependency 'hyper-store', Hyperloop::Console::VERSION
  spec.add_development_dependency 'hyperstack-config', Hyperloop::Console::VERSION
  spec.add_development_dependency 'opal', '>= 0.11.0', '< 0.12.0'
  spec.add_development_dependency 'opal-browser'
  spec.add_development_dependency 'opal-jquery'
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'uglifier', '4.1.6'
end
