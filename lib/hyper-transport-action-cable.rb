require 'hyper-transport'
require 'hyperstack/transport/action_cable/version'

if RUBY_ENGINE == 'opal'
  #require 'hyperstack/transport/action_cable/subscription'
  #require 'hyperstack/transport/action_cable/subscriptions'
  #require 'hyperstack/transport/action_cable/consumer'
  require 'hyperstack/transport/action_cable/client_driver'
else
  require 'hyperstack/transport/action_cable/channel'
  require 'hyperstack/transport/action_cable/server_driver'
  require 'hyperstack/transport/action_cable/config'
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end