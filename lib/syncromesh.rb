if RUBY_ENGINE == 'opal'

  require_relative 'syncromesh/version'
  require_relative 'active_record/base'
  require_relative 'reactive_record/syncromesh'
  require_relative 'reactive_record/base'
  require_relative 'reactive_record/sync_wrapper'

else

  require 'opal'
  require "syncromesh/version"
  require 'syncromesh/syncromesh'
  require 'syncromesh/simple_poller'
  require 'reactive_record/syncromesh_controller'

  Opal.append_path File.expand_path('../', __FILE__).untaint

end
