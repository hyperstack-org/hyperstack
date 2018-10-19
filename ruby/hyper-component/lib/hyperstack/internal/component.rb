module Hyperstack
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
