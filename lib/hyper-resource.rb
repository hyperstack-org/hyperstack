require 'hyperloop-config'
require 'hyperloop/hyper_resource_settings'
require 'opal-activesupport'
require 'hyper-store'
Hyperloop.import 'pusher/source/pusher.js', client_only: true
Hyperloop.import 'hyper-resource'
require 'hyperloop/resource/version'

if RUBY_ENGINE == 'opal'
  require 'hyper-store'
  require 'hyper_record'
else
  require 'hyper_record/client_drivers'
  require 'hyperloop/resource/pub_sub'
  Opal.append_path __dir__.untaint
end
