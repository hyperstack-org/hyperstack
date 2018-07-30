require 'hyperloop/transport/version'
if RUBY_ENGINE == 'opal'
  require 'hyperloop/transport/response_processor'
  require 'hyperloop/transport/notification_processor'
  require 'hyperloop/transport/client_drivers' # initialize options for the client
else
  require 'hyper-react'
  require 'hyperloop/transport/config'
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end
