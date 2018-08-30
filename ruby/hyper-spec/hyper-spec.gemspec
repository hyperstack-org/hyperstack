require '../version.rb'

Gem::Specification.new do |s|
  s.name         = 'hyper-spec'
  s.version      = Hyperstack::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'https://github.com/janbiedermann/hyper-gate'
  s.summary      = 'Spec for hyperstack.'
  s.description  = 'Spec for hyperstack.'

  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

end
