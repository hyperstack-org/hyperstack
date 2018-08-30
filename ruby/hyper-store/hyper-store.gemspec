# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require '../version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'hyper-store'
  spec.version       = Hyperstack::VERSION
  spec.authors       = ['Mitch VanDuyn', 'Adam Creekroad', 'Jan Biedermann']
  spec.email         = ['mitch@catprint.com', 'jan@kursator.com']
  spec.summary       = 'Flux Stores and more for Hyperstack'
  spec.homepage      = 'https://ruby-hyperstack.org'
  spec.license       = 'MIT'
  # spec.metadata      = {
  #   "homepage_uri" => 'http://ruby-hyperstack.org',
  #   "source_code_uri" => 'https://github.com/ruby-hyperstack/hyper-component'
  # }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(gemfiles|spec)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'opal', '>= 0.11.0', '< 0.12.0'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'hyper-react', Hyperstack::VERSION
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'opal-browser', '~> 0.2.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.7.0'
  spec.add_development_dependency 'rspec-steps', '~> 2.1.1'
  spec.add_development_dependency 'rubocop', '~> 0.51.0'
  spec.add_development_dependency 'sqlite3'
end
