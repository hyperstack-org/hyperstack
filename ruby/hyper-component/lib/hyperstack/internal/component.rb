require 'hyperstack-config'

module Hyperstack

  define_setting :prerendering, :off if RUBY_ENGINE != 'opal'

  module Internal
    module Component
      class << self
        def mounted_components
          @mounted_components ||= Set.new
        end
      end
    end
  end
end
