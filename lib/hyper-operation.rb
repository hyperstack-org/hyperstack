require "hyper-operation/version"

if RUBY_ENGINE == 'opal'
  require 'active_support/core_ext/string'
  require 'mutations'
  require 'hyper-operation/filters/outbound_filter'
  require 'hyper-operation/call_by_class_name'
  require 'hyper-react'
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
else
  require 'mutations'
  require 'hyper-operation/filters/outbound_filter'
  require 'hyper-react'
  require 'opal-activesupport'
  require 'hyper-operation/delay_and_interval'
  require 'hyper-operation/dispatcher'
  require 'hyper-operation/exception'
  require 'hyper-operation/execute'
  require 'hyper-operation/params_wrapper'
  require 'hyper-operation/promise'
  require 'hyper-operation/call_by_class_name'
  Opal.use_gem 'mutations'
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end
