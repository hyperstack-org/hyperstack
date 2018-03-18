require 'hyperloop-config'
require 'opal-activesupport'
require 'hyper-store'
Hyperloop.import 'pusher/source/pusher.js', client_only: true
Hyperloop.import 'hyper-resource'
require 'hyperloop/resource/version'

if RUBY_ENGINE == 'opal'
  require 'hyper-store'
else
  Opal.append_path __dir__.untaint
end
