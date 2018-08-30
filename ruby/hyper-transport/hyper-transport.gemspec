require '../version.rb'

Gem::Specification.new do |s|
  s.name         = 'hyper-transport'
  s.version      = Hyperstack::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'https://github.com/janbiedermann/hyper-transport'
  s.summary      = 'Various client side transport options for ruby-hyperstack or hyper-stack.'
  s.description  = 'Various client side transport options for ruby-hyperstack or hyper-stack.'

  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_runtime_dependency 'opal', '~> 0.11.0'
  s.add_runtime_dependency 'hyper-react', Hyperstack::VERSION
end
