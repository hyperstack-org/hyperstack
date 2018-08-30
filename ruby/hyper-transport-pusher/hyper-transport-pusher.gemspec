require '../version.rb'

Gem::Specification.new do |s|
  s.name         = 'hyper-transport-pusher'
  s.version      = Hyperstack::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'https://github.com/janbiedermann/hyper-transport-pusher'
  s.summary      = 'Driver for Pusher.com pub sub service for hyper-transport for hyperstack.'
  s.description  = 'Driver for Pusher.com pub sub service for hyper-transport for hyperstack.'

  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_runtime_dependency 'opal', '~> 0.11.0'
  s.add_runtime_dependency 'hyper-transport', Hyperstack::VERSION
end
