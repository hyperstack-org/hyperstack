require 'hyperloop/transport/version'
require 'hyper-transport'

if RUBY_ENGINE == 'opal'
  require 'hyperloop/transport/action_cable/subscription'
  require 'hyperloop/transport/action_cable/subscriptions'
  require 'hyperloop/transport/action_cable/consumer'
else
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end