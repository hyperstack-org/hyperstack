# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperloop/config/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyperloop-config'
  spec.version       = Hyperloop::Config::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = %q{Provides a single point configuration module for hyperloop gems}
  spec.homepage      = 'http://ruby-hyperloop.org'
  spec.license       = 'MIT'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperloop.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperloop/hyper-component'
  # }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'opal', '>= 0.11.0', '< 0.12.0'
  spec.add_dependency 'opal-browser', '~> 0.2.0'
  spec.add_dependency 'uglifier'
  spec.add_dependency 'mini_racer', '~> 0.1.15'
  # https://github.com/discourse/mini_racer/issues/92
  spec.add_dependency 'libv8', '~> 6.3.0'

  spec.add_development_dependency 'bundler', '~> 1.16.0'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'hyper-spec', Hyperloop::Config::VERSION
  spec.add_development_dependency 'opal-rails', '~> 0.9.4'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.7.0'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop', '~> 0.8.1'
end
