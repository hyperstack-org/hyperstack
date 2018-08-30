require '../version.rb'

Gem::Specification.new do |s|
  s.name         = 'hyper-transport-store-redis'
  s.version      = Hyperstack::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'https://github.com/janbiedermann/hyper-transport-store-redis'
  s.summary      = 'Subscriptions store for hyper-transport for hyperstack.'
  s.description  = 'Subscriptions store for hyper-transport for hyperstack.'

  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_runtime_dependency 'hyper-transport', Hyperstack::VERSION
  s.add_runtime_dependency 'redis', '~> 4.0.1'
end
