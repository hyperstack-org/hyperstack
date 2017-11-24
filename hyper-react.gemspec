# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)

require 'reactive-ruby/version'

Gem::Specification.new do |s|
  s.name         = 'hyper-react'
  s.version      = React::VERSION

  s.authors       = ['David Chang', 'Adam Jahn', 'Mitch VanDuyn', 'janbiedermann']
  s.email        = 'reactrb@catprint.com'
  s.homepage     = 'http://ruby-hyperloop.io/gems/reactrb/'
  s.summary      = 'Opal Ruby wrapper of React.js library.'
  s.license      = 'MIT'
  s.description  = 'Write React UI components in pure Ruby.'
  s.files          = `git ls-files`.split("\n")
  s.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_dependency 'hyper-store', '0.15.0-sachsenring-lap5'
  s.add_dependency 'opal', '~> 0.10.5'
  s.add_dependency 'opal-activesupport', '~> 0.3.0'

  s.add_development_dependency 'listen'
  s.add_development_dependency 'mime-types'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'opal-rails', '~> 0.9.3'
  s.add_development_dependency 'opal-rspec'
  s.add_development_dependency 'rails', '~> 5.1.4'
  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'react-rails', '>= 2.3.0', '< 2.5.0'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop', '~> 0.51.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'mini_racer', '~> 0.1.14'
  s.add_development_dependency 'timecop', '~> 0.8.1'
end
