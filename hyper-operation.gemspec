# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyper-operation/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-operation'
  spec.version       = Hyperloop::Operation::VERSION
  spec.authors       = ['catmando', 'janbiedermann']
  spec.email         = ['mitch@catprint.com']

  spec.summary       = %q{Compose your business logic into isomorphic commands that sanitize and validate input. Write safe, reusable, and maintainable code for Ruby and Rails app}
  spec.homepage      = 'http://ruby-hyperloop.io'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 5.1.4'
  spec.add_dependency 'hyper-component', '0.15.3'
  spec.add_dependency 'hyperloop-config', '0.15.3'
  spec.add_dependency 'mutations'
  spec.add_dependency 'opal-activesupport'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'hyper-react', '0.15.3'
  spec.add_development_dependency 'hyper-spec', '0.15.3'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'opal-browser'
  spec.add_development_dependency 'opal-rails', '~> 0.9.3'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'pusher'
  spec.add_development_dependency 'pusher-fake'
  spec.add_development_dependency 'rails', '>= 5.1.4'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-steps'
  spec.add_development_dependency 'rspec-wait'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop', '~> 0.8.1'
end
