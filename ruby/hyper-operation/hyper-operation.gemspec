require '../version.rb'

Gem::Specification.new do |s|
  s.name         = 'hyper-operation'
  s.version      = Hyperstack::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'https://github.com/janbiedermann/hyper-business'
  s.summary      = 'Business operations for hyper-stack.'
  s.description  = 'Business operations for hyper-stack.'
  s.executables << 'hyper-business-installer'
  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_runtime_dependency 'opal', '~> 0.11.0'
  s.add_runtime_dependency 'opal-activesupport', '~> 0.3.1'
  s.add_runtime_dependency 'hyper-react', Hyperstack::VERSION
  s.add_runtime_dependency 'hyper-transport', Hyperstack::VERSION
  s.add_runtime_dependency 'oj', '~> 3.6.0'
end
