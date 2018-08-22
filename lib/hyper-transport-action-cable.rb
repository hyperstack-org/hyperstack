require 'hyper-transport'
require 'hyperstack/transport/action_cable/version'

if RUBY_ENGINE == 'opal'
  require 'hyperstack/transport/action_cable/subscription'
  require 'hyperstack/transport/action_cable/subscriptions'
  require 'hyperstack/transport/action_cable/consumer'
else
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end