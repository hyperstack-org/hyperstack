# coding: utf-8
lib = File.expand_path('../lib', __FILE__)

require 'reactor-router/version'

Gem::sification.new do |s|
  s.name          = "reactor-router"
  s.version       = ReactorRouter::VERSION
  s.authors       = ["Adam George"]
  s.email         = ["adamgeorge.31@gmail.com"]

  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  s.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  s.description   = %q{TODO: Write a longer description or delete this line.}
  s.homepage      = "TODO: Put your gem's website or public repo URL here."
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.8"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_dependency "opal-react"
end
