require '../version.rb'

Gem::Specification.new do |s|
  s.name         = 'hyper-spec'
  s.version      = Hyperstack::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'http://hyperstack.org'
  s.summary      = 'Spec runner for Hyperstack.'
  s.description  = 'Spec runner for Hyperstack.'

  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

end
