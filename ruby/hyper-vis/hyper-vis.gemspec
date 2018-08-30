require '../version.rb'

Gem::Specification.new do |s|
  s.name         = 'hyper-vis'
  s.version      = Hyperstack::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'https://github.com/janbiedermann/hyper-vis'
  s.summary      = 'A Opal Ruby wraper for Vis.js with a Hyperstack Component.'
  s.description  = 'Write React Components in ruby to show graphics created with Vis.js in the ruby way'

  s.files          = `git ls-files`.split('\n')
  s.executables    = `git ls-files -- bin/*`.split('\n').map { |f| File.basename(f) }
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_runtime_dependency 'opal', '~> 0.11.0'
  s.add_runtime_dependency 'opal-activesupport', '~> 0.3.1'
  s.add_runtime_dependency 'hyper-component', Hyperstack::VERSION
  s.add_development_dependency 'listen'
  s.add_development_dependency 'rake', '>= 11.3.0'
  s.add_development_dependency 'rails', '>= 5.1.0'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sqlite3'
end
