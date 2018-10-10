require 'set'
require 'hyperstack-config'
Hyperstack.import 'hyper-state'

require 'hyperstack/internal/state/mapper'
require 'hyperstack/internal/state/mutable'
require 'hyperstack/internal/state/wrapper'
require 'hyperstack/state/observable'
require 'hyperstack/state/observer'
require 'hyperstack/state/variable'
require 'hyperstack/state/version'

if RUBY_ENGINE != 'opal'
  require 'opal'
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
