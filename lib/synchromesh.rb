if RUBY_ENGINE == 'opal'
  require_relative 'synchromesh/version'
  require_relative 'reactive_record/base'
  require_relative 'reactive_record/sync_wrapper'
else
  require 'opal'
  require 'reactrb'
  require 'reactive-record'
  require 'synchromesh/version'
  require 'synchromesh/synchromesh'
  require 'synchromesh/simple_poller'
  require_relative 'reactive_record/synchromesh_controller'
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
end
require_relative 'client/synchromesh'
require_relative 'active_record/base'
