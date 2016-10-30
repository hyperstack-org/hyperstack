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
  require "hyper-react"
  require "reactive_record/active_record/error"
  require "reactive_record/server_data_cache"
  require "reactive_record/active_record/reactive_record/while_loading"
  require "reactive_record/active_record/reactive_record/isomorphic_base"
  require "reactive_record/active_record/aggregations"
  require "reactive_record/active_record/associations"
  require "reactive_record/active_record/reactive_record/base"
  require "reactive_record/active_record/reactive_record/collection"
  require "reactive_record/active_record/class_methods"
  require "reactive_record/active_record/instance_methods"
  require "reactive_record/active_record/base"
  require "reactive_record/interval"
  require_relative 'active_record_base'
  require_relative 'synchromesh/version'
  require_relative 'opal/parse_patch'
  require_relative 'opal/set_patches'
  #require_relative 'reactive_record_patches/base'
  require_relative 'reactive_record_patches/collection'
  require_relative 'reactive_record/scope_description'
else
  require 'opal'
  require 'hyper-react'
  require "reactive_record/permissions"
  require "reactive_record/engine"
  require "reactive_record/server_data_cache"
  require "reactive_record/active_record/reactive_record/isomorphic_base"
  require "reactive_record/serializers"
  require "reactive_record/pry"
  require_relative 'active_record_base'
  require 'synchromesh/synchromesh_controller'
  require 'synchromesh/version'
  require 'synchromesh/connection'
  require 'synchromesh/synchromesh'
  require 'synchromesh/policy'
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
end
require_relative 'synchromesh/client_drivers'
