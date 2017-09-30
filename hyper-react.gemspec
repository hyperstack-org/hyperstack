# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)

require 'reactive-ruby/version'

Gem::Specification.new do |s|
  s.name         = 'hyper-react'
  s.version      = React::VERSION

  s.authors       = ['David Chang', 'Adam Jahn', 'Mitch VanDuyn']
  s.email        = 'reactrb@catprint.com'
  s.homepage     = 'http://ruby-hyperloop.io/gems/reactrb/'
  s.summary      = 'Opal Ruby wrapper of React.js library.'
  s.license      = 'MIT'
  s.description  = "Write React UI components in pure Ruby."
  s.files          = `git ls-files`.split("\n")
  s.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_dependency 'opal'
  s.add_dependency 'opal-activesupport'
  s.add_dependency 'hyper-store', '>= 0.2.1'
  s.add_dependency 'hyperloop-config', '>= 0.9.7'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'opal-rspec'
  s.add_development_dependency 'sinatra'
  s.add_development_dependency 'opal-jquery'

  # For Test Rails App
  s.add_development_dependency 'rails'
  s.add_development_dependency 'mime-types'
  s.add_development_dependency 'listen'
  s.add_development_dependency 'opal-rails'
  s.add_development_dependency 'react-rails', '>= 2.3.0'
  s.add_development_dependency 'rails-controller-testing'

  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'rubocop'
  if RUBY_PLATFORM == 'java'
    s.add_development_dependency 'jdbc-sqlite3'
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
    s.add_development_dependency 'therubyrhino'
  else
    s.add_development_dependency 'sqlite3'
    s.add_development_dependency 'therubyracer'
  end
end
