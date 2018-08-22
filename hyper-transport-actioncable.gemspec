require_relative 'lib/hyperstack/transport/action_cable/version'

Gem::Specification.new do |s|
  s.name         = 'hyper-transport-actioncable'
  s.version      = Hyperstack::Transport::ActionCable::VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'https://github.com/janbiedermann/hyper-transport-actioncable'
  s.summary      = 'Driver for ActionCable pub sub for hyper-transport for hyperstack.'
  s.description  = 'Driver for ActionCable pub sub for hyper-transport for hyperstack.'

  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_runtime_dependency 'opal', '~> 0.11.0'
  s.add_runtime_dependency 'hyper-transport', '~> 0.0.1'
end
