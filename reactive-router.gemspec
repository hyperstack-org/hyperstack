# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require 'reactive-router/version'

Gem::Specification.new do |s|
  s.name          = "reactive-router"
  s.version       = ReactiveRouter::VERSION
  s.authors       = ["Adam George"]
  s.email         = ["adamgeorge.31@gmail.com"]
  s.summary       = "react-router for Opal, part of the reactive-ruby gem family"
  s.description   = "Adds the ability to write and use the react-router in Ruby through Opal"
  s.files = Dir["{lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]

  s.add_development_dependency "bundler", "~> 1.8"
  s.add_development_dependency "rake", "~> 10.0"
  #s.add_dependency "opal-rails"
  #s.add_dependency "react-rails"
  s.add_dependency "reactive-ruby"
  #s.add_dependency "react-router-rails", '~>0.13.3'

  #s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec-rails', '3.3.3'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'opal-rspec', '0.4.3'
  s.add_development_dependency 'sinatra'

  # For Test Rails App
  s.add_development_dependency 'rails', '4.2.4'
  s.add_development_dependency 'react-rails', '1.3.1'
  s.add_development_dependency 'opal-rails', '0.8.1'

  if RUBY_PLATFORM == 'java'
    s.add_development_dependency 'jdbc-sqlite3'
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
    s.add_development_dependency 'therubyrhino'
  else
    s.add_development_dependency 'sqlite3', '1.3.10'
    s.add_development_dependency 'therubyracer', '0.12.2'
  end
end
