# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperstack/version'

Gem::Specification.new do |spec|
  spec.name        = 'rails-hyperstack'
  spec.version     = Hyperstack::VERSION
  spec.summary     = 'Hyperstack for Rails with generators'
  spec.description = 'This gem provide a full hyperstack for rails plus generators for Hyperstack elements'
  spec.authors     = ['Loic Boutet', 'Adam George', 'Mitch VanDuyn', 'Jan Biedermann']
  spec.email       = ['loic@boutet.com', 'jan@kursator.com']
  spec.homepage    = 'http://hyperstack.org'
  spec.metadata    = { 'documentation_uri' => 'https://docs.hyperstack.org/' }
  spec.license     = 'MIT'
  # spec.metadata = {
  #   "homepage_uri" => 'http://hyperstack.org',
  #   "source_code_uri" => 'https://github.com/hyperstack
  # }
  spec.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(tasks)/}) }
  spec.require_paths = ['lib']
  spec.post_install_message = %q{
*******************************************************************************

Welcome to Hyperstack!

For a quick start simply add a component using one of the generators:

  >> bundle exec rails generate hyper:component CompName --add-route="/test/(*others)"
     # Add a new component named CompName and route to it with /test/

  >> bundle exec rails generate hyper:router CompName --add-route="/test/(*others)"
     # Add a top level router named CompName and route to it

The generators will insure you have the minimal additions to your system for the
new component to run.  And note: --add-route is optional.

For a complete install run the hyperstack install task:

  >> bundle exec rails hyperstack:install

This will add everything you need including the hotloader, webpack integration,
hyper-model (active record model client synchronization) and a top level
component to get you started.

You can control how much of the stack gets installed as well:

  >> bundle exec rails hyperstack:install:webpack          # just add webpack
  >> bundle exec rails hyperstack:install:skip-webpack     # all but webpack
  >> bundle exec rails hyperstack:install:hyper-model      # just add hyper-model
  >> bundle exec rails hyperstack:install:skip-hyper-model # all but hyper-model
  >> bundle exec rails hyperstack:install:hotloader        # just add the hotloader
  >> bundle exec rails hyperstack:install:skip-hotloader   # skip the hotloader

*******************************************************************************
}

  spec.add_dependency 'hyper-model', Hyperstack::VERSION
  spec.add_dependency 'hyper-router', Hyperstack::ROUTERVERSION
  spec.add_dependency 'hyperstack-config', Hyperstack::VERSION
  spec.add_dependency 'opal-rails' #, '~> 2.0'

  spec.add_dependency 'opal-browser', '~> 0.2.0'
  spec.add_dependency 'react-rails', '>= 2.4.0', '< 2.7.0'
  # spec.add_dependency 'mini_racer', '~> 0.2.6'
  # spec.add_dependency 'libv8', '~> 7.3.492.27.1'
  spec.add_dependency 'rails', ENV['RAILS_VERSION'] || '>= 5.0.0', '< 7.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'hyper-spec', Hyperstack::VERSION
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'bootsnap'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop' #, '~> 0.51.0'
  spec.add_development_dependency 'sqlite3', '~> 1.4' # was 1.3.6 -- see https://github.com/rails/rails/issues/35153
  spec.add_development_dependency 'sass-rails', '>= 5.0'
  # Use Uglifier as compressor for JavaScript assets
  spec.add_development_dependency 'uglifier', '>= 1.3.0'
  # See https://github.com/rails/execjs#readme for more supported runtimes
  # gem 'mini_racer', platforms: :ruby

  # Use CoffeeScript for .coffee assets and views
  #spec.add_development_dependency 'coffee-rails', '~> 4.2'
  # Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
  spec.add_development_dependency 'turbolinks', '~> 5'
  # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
  spec.add_development_dependency 'jbuilder', '~> 2.5'
  spec.add_development_dependency 'foreman'
  spec.add_development_dependency 'database_cleaner'
end
