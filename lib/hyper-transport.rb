require 'hyperstack/transport/version'
if RUBY_ENGINE == 'opal'
  require 'hyperstack/transport/request_agent'
  require 'hyperstack/transport/response_processor'
  require 'hyperstack/transport/notification_processor'
  require 'hyperstack/transport/client_drivers'
else
  require 'hyperstack/promise'
  require 'hyperstack/transport/config'
  require 'hyperstack/transport/server_pub_sub'
  require 'hyperstack/transport/request_processor'
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end
