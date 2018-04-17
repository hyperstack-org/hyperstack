require 'set'
require 'hyperloop-config'
require 'hyper-component'
if RUBY_ENGINE == 'opal'
  require 'hyper-operation'
  require 'active_support'
  require 'time'
  require 'date'
  require 'kernel/itself' unless Object.instance_methods.include?(:itself)
  require 'object/tap'
  require "reactive_record/active_record_error"
  require "reactive_record/active_record/errors"
  require "reactive_record/active_record/error"
  require "reactive_record/server_data_cache"
  require "reactive_record/active_record/reactive_record/while_loading"
  require "reactive_record/active_record/reactive_record/operations"
  require 'reactive_record/broadcast'
  require "reactive_record/active_record/reactive_record/isomorphic_base"
  require 'reactive_record/active_record/reactive_record/dummy_value'
  require 'reactive_record/active_record/reactive_record/column_types'
  require "reactive_record/active_record/aggregations"
  require "reactive_record/active_record/associations"
  require "reactive_record/active_record/reactive_record/backing_record_inspector"
  require "reactive_record/active_record/reactive_record/getters"
  require "reactive_record/active_record/reactive_record/setters"
  require "reactive_record/active_record/reactive_record/lookup_tables"
  require "reactive_record/active_record/reactive_record/base"
  require "reactive_record/active_record/reactive_record/collection"
  require "reactive_record/active_record/reactive_record/scoped_collection"
  require "reactive_record/active_record/reactive_record/unscoped_collection"
  require "reactive_record/interval"
  require_relative 'active_record_base'
  require_relative 'reactive_record/scope_description'
  require "reactive_record/active_record/class_methods"
  require "reactive_record/active_record/instance_methods"
  require "reactive_record/active_record/base"
  require_relative 'hypermesh/version'
  require_relative 'opal/parse_patch'
  require_relative 'opal/set_patches'
  require_relative 'opal/equality_patches'
  React::IsomorphicHelpers.log(
    "The gem 'hyper-mesh' is deprecated.  Use gem 'hyper-model' instead.", :warning
  ) unless defined? Hyperloop::Model
else
  require 'opal'
  require 'hyper-operation'
  require "reactive_record/permissions"
  require "reactive_record/server_data_cache"
  require "reactive_record/active_record/reactive_record/operations"
  require 'reactive_record/broadcast'
  require "reactive_record/active_record/reactive_record/isomorphic_base"
  require "reactive_record/active_record/public_columns_hash"
  require "reactive_record/serializers"
  require "reactive_record/pry"
  require_relative 'active_record_base'
  require 'hypermesh/version'

  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end
require 'enumerable/pluck'
