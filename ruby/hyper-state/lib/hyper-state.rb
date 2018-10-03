require 'set'
require 'hyperstack-config'
Hyperstack.import 'hyper-state'

require 'hyperstack/internal/state/class_methods'
require 'hyperstack/internal/state/instance_methods'
require 'hyperstack/internal/state/observer'
require 'hyperstack/internal/state/wrapper_methods'
require 'hyperstack/internal/state'
require 'hyperstack/state/version'
require 'hyperstack/state'

if RUBY_ENGINE != 'opal'
  require 'opal'
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
