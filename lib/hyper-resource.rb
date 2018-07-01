require 'opal-activesupport'
require 'hyperloop/resource/version'
require 'reactive-ruby/isomorphic_helpers'
require 'hyperloop/resource/client_drivers' # initialize options for the client
require 'hyperloop/resource/config'
require 'hyper-store'

if RUBY_ENGINE == 'opal'
  require 'hyperloop/resource/http'
  require 'hyper-store'
  require 'hyper_record'
else
  require 'hyperloop/resource/pub_sub' # server side, controller helper methods
  require 'hyperloop/resource/security_guards' # server side, controller helper methods
  require 'hyper_record'
  Opal.append_path(__dir__.untaint)
  if Dir.exist?(File.join('app', 'hyperloop', 'models'))
    Opal.append_path(File.expand_path(File.join('app', 'hyperloop', 'models')))
  elsif Dir.exist?(File.join('hyperloop', 'models'))
    Opal.append_path(File.expand_path(File.join('hyperloop', 'models')))
  end
end
