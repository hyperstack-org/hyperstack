require 'set'
require 'hyperstack-config'
require 'hyper-state'
Hyperstack.import 'hyper-store'

module Hyperstack
  module Internal
    module Store
      # allows us to easily turn off BasicObject for debug
      class BaseStoreClass < BasicObject
      end
    end
  end
end

require 'hyperstack/internal/store/class_methods'
require 'hyperstack/internal/store/dispatch_receiver'
require 'hyperstack/internal/store/instance_methods'
require 'hyperstack/internal/store/mutator_wrapper'
require 'hyperstack/internal/store/observable'
require 'hyperstack/internal/store/state_wrapper/argument_validator'
require 'hyperstack/internal/store/state_wrapper'
require 'hyperstack/legacy/store'
require 'hyperstack/legacy/store/version'

if RUBY_ENGINE != 'opal'
  require 'opal'
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
