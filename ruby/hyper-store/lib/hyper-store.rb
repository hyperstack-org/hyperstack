require 'set'
require 'hyperloop-config'
Hyperloop.import 'hyper-store'


module HyperStore # allows us to easily turn off BasicObject for debug
  class BaseStoreClass < BasicObject
  end
end

require 'hyper-store/class_methods'
require 'hyper-store/dispatch_receiver'
require 'hyper-store/instance_methods'
require 'hyper-store/mutator_wrapper'
require 'hyper-store/state_wrapper/argument_validator'
require 'hyper-store/state_wrapper'
require 'hyper-store/version'
require 'hyperloop/store'
require 'hyperloop/application/boot'
require 'hyperloop/store/mixin'
require 'react/state'

if RUBY_ENGINE != 'opal'
  require 'opal'
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
