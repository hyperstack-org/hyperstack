require 'hyper-transport'

if RUBY_ENGINE == 'opal'
  require 'hyperstack/transport/pusher/client_driver'
else
  require 'hyperstack/transport/pusher/server_driver'
  require 'hyperstack/transport/pusher/config'
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end