# module ApplicationCable
#   class Connection < ActionCable::Connection::Base
#     # we always create a connection, and use the session_id to identify it.
#     #identified_by :session
#
#     # def connect
#     #   #self.session = cookies.encrypted[Rails.application.config.session_options[:key]]
#     # end
#   end
# end

require_relative 'active_record_base'
require 'set'
if RUBY_ENGINE == 'opal'
  #require 'reactive-record'
  require_relative 'synchromesh/version'
  require_relative 'json/parse_patch'
  require_relative 'opal/set_patches'
  require_relative 'react/component_patches'
  require_relative 'react/state_patches'
  require_relative 'reactive_record/base'
  require_relative 'reactive_record/collection'
  require_relative 'reactive_record/while_loading'
  require_relative 'reactive_record/scope_description'
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
  #require 'active_record/transactions'
  require 'reactive-record'
  require 'reactive_record/permission_patches'
  require 'reactive_record/synchromesh_controller'
  require 'synchromesh/version'
  require 'synchromesh/connection'
  require 'react/isomorphic_helpers_patches'
  require 'synchromesh/synchromesh'
  require 'synchromesh/policy'
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
end
require_relative 'synchromesh/client_drivers'
