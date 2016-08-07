if RUBY_ENGINE == 'opal'
  require_relative 'synchromesh/version'
  require_relative 'json/parse_patch'
  require_relative 'reactive_record/base'
  require_relative 'reactive_record/sync_wrapper'
else
  require 'opal'
  # This is temporarily needed so that the todo-tutorial
  # which is still using reactive-ruby, will work.  Once
  # the todo-tutorial is updated, this can be a straight
  # require of reactrb.
  begin
    require 'reactrb'
  rescue LoadError
  end
  require 'reactive-record'
  require 'synchromesh/version'
  require 'synchromesh/synchromesh'
  require 'synchromesh/simple_poller'
  require_relative 'reactive_record/synchromesh_controller'
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
end
require_relative 'synchromesh/client_drivers'
require_relative 'active_record/base'
