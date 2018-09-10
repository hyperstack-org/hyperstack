# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperloop/model/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-model'
  spec.version       = Hyperloop::Model::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = %q{Isomorphic ActiveRecord wrapper for Hyperloop}
  spec.description   = 'HyperModel gives your HyperComponents CRUD access to your '\
                       'ActiveRecord models on the client, using the the standard ActiveRecord '\
                       'API. HyperModel also implements push notifications (via a number of '\
                       'possible technologies) so changes to records on the server are '\
                       'dynamically updated on all authorised clients.'
  spec.homepage      = 'http://ruby-hyperloop.org'
  spec.license       = 'MIT'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperloop.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperloop/hyper-component'
  # }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(examples|spec)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'hyper-mesh', Hyperloop::Model::VERSION
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'hyper-spec', Hyperloop::Model::VERSION
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'mini_racer', '~> 0.1.15'
  spec.add_development_dependency 'opal', '>= 0.11.0', '< 0.12.0'
  spec.add_development_dependency 'opal-browser', '~> 0.2.0'
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'react-rails', '>= 2.4.0', '< 2.5.0'
  spec.add_development_dependency 'rspec', '~> 3.7.0'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'sqlite3'
end
