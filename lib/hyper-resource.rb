require 'hyperloop-config'
require 'opal-activesupport'
Hyperloop.import 'pusher/source/pusher.js', client_only: true
require 'hyperloop/resource/version'
require 'reactive-ruby/isomorphic_helpers'
require 'hyperloop/resource/client_drivers' # initialize options for the client
require 'hyperloop/resource/config'
require 'hyper-store'
Hyperloop.import 'hyper-resource'


if RUBY_ENGINE == 'opal'
  require 'hyperloop/resource/http'
  require 'hyper-store'
  require 'hyper_record'
else
  require 'hyperloop/resource/pub_sub' # server side, controller helper methods
  require 'hyperloop/resource/security_guards' # server side, controller helper methods
  require 'hyper_record'
  Opal.append_path __dir__.untaint
end
