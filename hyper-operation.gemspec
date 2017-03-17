# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-operation/version'

Gem::Specification.new do |spec|
  spec.name          = "hyper-operation"
  spec.version       = Hyperloop::Operation::VERSION
  spec.authors       = ["catmando"]
  spec.email         = ["mitch@catprint.com"]

  spec.summary       = %q{Compose your business logic into isomorphic commands that sanitize and validate input. Write safe, reusable, and maintainable code for Ruby and Rails app}
  spec.homepage      = "http://ruby-hyperloop.io"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'mutations'
  spec.add_dependency 'hyper-component', '>= 0.12.2'
  spec.add_dependency 'hyperloop-config', '>= 0.9.2'
  spec.add_dependency 'opal-activesupport'
  spec.add_dependency 'activerecord', '>= 0.3.0'
  spec.add_dependency 'pusher'
  spec.add_dependency 'pusher-fake'

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'hyper-spec'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rails', '~>5.0.0'
  spec.add_development_dependency 'opal-rails'
  spec.add_development_dependency 'hyper-react'
  spec.add_development_dependency 'opal-browser'
  spec.add_development_dependency 'sqlite3', '1.3.10'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec-wait'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rspec-steps'

end
