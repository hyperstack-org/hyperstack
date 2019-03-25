require 'hyperstack-config'

module Hyperstack
  define_setting :prerendering, :off if RUBY_ENGINE != 'opal'

  module Internal
    module Component
      class << self
        attr_accessor :after_error_args
      end
    end
  end
end
