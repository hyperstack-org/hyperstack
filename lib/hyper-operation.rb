require 'hyper-operation/version'
require 'hyperloop-config'
Hyperloop.import 'browser/interval', client_only: true
Hyperloop.import 'hyper-operation'

if RUBY_ENGINE == 'opal'
  require 'active_support/core_ext/string'
  require 'mutations'
  require 'hyper-operation/filters/outbound_filter'
  require 'hyper-component'
  require 'hyper-operation/call_by_class_name'
  require 'hyper-operation/transport/client_drivers'
  class HashWithIndifferentAccess < Hash
  end
  class String
    def titleize
      self
    end
  end
  require 'hyper-operation/exception'
  require 'hyper-operation/promise'
  require 'hyper-operation/railway'
  require 'hyper-operation/api'
  require 'hyper-operation/railway/dispatcher'
  require 'hyper-operation/railway/params_wrapper'
  require 'hyper-operation/railway/run'
  require 'hyper-operation/railway/validations'
  require 'hyper-operation/server_op'
  require 'hyper-operation/boot'
else
  require 'hyperloop-config'
  require 'mutations'
  require 'hyper-operation/filters/outbound_filter'
  require 'hyper-component'
  require 'active_record'
  require 'hyper-operation/transport/active_record'
  require 'hyper-operation/engine'
  require 'hyper-operation/transport/connection'
  require 'hyper-operation/transport/hyperloop'
  require 'hyper-operation/transport/policy'
  require 'hyper-operation/transport/client_drivers'
  require 'hyper-operation/transport/acting_user'
  require 'opal-activesupport'
  require 'hyper-operation/delay_and_interval'
  require 'hyper-operation/exception'
  require 'hyper-operation/promise'
  require 'hyper-operation/call_by_class_name'
  require 'hyper-operation/railway'
  require 'hyper-operation/api'
  require 'hyper-operation/railway/dispatcher'
  require 'hyper-operation/railway/params_wrapper'
  require 'hyper-operation/railway/run.rb'
  require 'hyper-operation/railway/validations'
  require 'hyper-operation/transport/hyperloop_controller'
  require 'hyper-operation/server_op'
  Opal.use_gem 'mutations', false
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end
