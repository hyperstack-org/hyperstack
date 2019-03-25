# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper_trace/version'

Gem::Specification.new do |spec|
  spec.name          = "hyper-trace"
  spec.version       = HyperTrace::VERSION
  spec.authors       = ["catmando"]
  spec.email         = ["mitch@catprint.com"]

  spec.summary       = %q{Method tracing and conditional breakpoints for Opal Ruby}
  spec.homepage      = "https://github.com/reactrb/hyper-trace"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'hyperstack-config', HyperTrace::VERSION
  spec.add_development_dependency "bundler", ['>= 1.17.3', '< 2.1']
  spec.add_development_dependency 'chromedriver-helper'
  spec.add_development_dependency "rake", "~> 10.0"
end
