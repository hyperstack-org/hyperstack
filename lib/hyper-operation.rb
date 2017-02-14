require "hyper-operation/version"

if RUBY_ENGINE == 'opal'
  require 'active_support/core_ext/string'
  require 'mutations'
  require 'hyper-operation/filters/outbound_filter'
  require 'hyper-operation/call_by_class_name'
  require 'hyper-react'
  require 'hyper-operation/transport/client_drivers'
  class HashWithIndifferentAccess < Hash
  end
  class String
    def titleize
      self
    end
  end
  require 'hyper-operation/dispatcher'
  require 'hyper-operation/exception'
  require 'hyper-operation/execute'
  require 'hyper-operation/params_wrapper'
  require 'hyper-operation/promise'
  require 'hyper-operation/boot'
  require 'hyper-operation/isomorphic_operations.rb'
else
  require 'mutations'
  require 'hyper-operation/filters/outbound_filter'
  require 'hyper-react'
  require 'active_record'
  require 'hyper-operation/transport/active_record'
  require 'hyper-operation/engine'
  require 'hyper-operation/transport/configuration'
  require 'hyper-operation/transport/connection'
  require 'hyper-operation/transport/hyperloop'
  require 'hyper-operation/transport/policy'
  require 'hyper-operation/transport/client_drivers'
  require 'hyper-operation/transport/acting_user'
  require 'opal-activesupport'
  require 'hyper-operation/delay_and_interval'
  require 'hyper-operation/dispatcher'
  require 'hyper-operation/exception'
  require 'hyper-operation/execute'
  require 'hyper-operation/params_wrapper'
  require 'hyper-operation/promise'
  require 'hyper-operation/call_by_class_name'
  require 'hyper-operation/isomorphic_operations.rb'
  Opal.use_gem 'mutations'
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end
