require 'hyperloop-config'
require 'hyperloop/resource/config'
require 'opal-activesupport'
require 'hyper-store'
Hyperloop.import 'pusher/source/pusher.js', client_only: true
Hyperloop.import 'hyper-resource'
require 'hyperloop/resource/version'

if RUBY_ENGINE == 'opal'
  require 'hyper-store'
  require 'hyper_record'
else
  require 'hyper_record/client_drivers' # initialize options for the client
  require 'hyperloop/resource/pub_sub' # server side, controller helper methods
  require 'hyperloop/resource/security_guards' # server side, controller helper methods
  Opal.append_path __dir__.untaint
end
