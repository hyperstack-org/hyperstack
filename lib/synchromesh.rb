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

require 'set'
if RUBY_ENGINE == 'opal'
  #require 'reactive-record'
    require "hyper-react"
    #require "json_parse_patch"
    require "reactive_record/active_record/error"
    require "reactive_record/server_data_cache"
    require "reactive_record/active_record/reactive_record/while_loading"
    require "reactive_record/active_record/reactive_record/isomorphic_base"
    require "reactive_record/active_record/aggregations"
    require "reactive_record/active_record/associations"
    require "reactive_record/active_record/reactive_record/base"
    require "reactive_record/active_record/reactive_record/collection"
    require "reactive_record/reactive_scope"
    require "reactive_record/active_record/class_methods"
    require "reactive_record/active_record/instance_methods"
    require "reactive_record/active_record/base"
    require "reactive_record/interval"
  #end requires from reactive-record
  require_relative 'active_record_base'
  #require_relative 'react/reset_prerender_history'
  require_relative 'synchromesh/version'
  require_relative 'json/parse_patch'
  require_relative 'opal/set_patches'
  #require_relative 'react/component_patches'
  #require_relative 'react/state_patches'
  require_relative 'reactive_record_patches/base'
  require_relative 'reactive_record_patches/collection'
  require_relative 'reactive_record_patches/while_loading'
  require_relative 'reactive_record_patches/scope_description'
  require_relative 'reactive_record_patches/sync_wrapper'
else
  require 'opal'
  # This is temporarily needed so that the todo-tutorial
  # which is still using reactive-ruby, will work.  Once
  # the todo-tutorial is updated, this can be a straight
  # require of hyper-react.
  begin
    require 'hyper-react'
  rescue LoadError
    puts "**************************** load error ********************"
  end
  #require 'active_record/transactions'
  #require 'reactive-record'
    require "reactive_record/permissions"
    require "reactive_record/engine"
    require "reactive_record/server_data_cache"
    require "reactive_record/active_record/reactive_record/isomorphic_base"
    require "reactive_record/reactive_scope"
    require "reactive_record/serializers"
    require "reactive_record/pry"
  # end requires from reactive-record
  require_relative 'active_record_base'
  #require 'reactive_record/permission_patches'
  require 'reactive_record_patches/synchromesh_controller'
  require 'reactive_record_patches/base_patches'
  require 'synchromesh/version'
  require 'synchromesh/connection'
  require 'react/isomorphic_helpers_patches'
  require 'synchromesh/synchromesh'
  require 'synchromesh/policy'
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
end
require_relative 'synchromesh/client_drivers'
