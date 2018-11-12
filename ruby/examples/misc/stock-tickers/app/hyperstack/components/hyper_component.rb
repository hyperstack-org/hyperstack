module Hyperstack
  module State
    module Observable
      def self.naming_convention
        :prefix_params
      end
    end
  end
end

class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
end.hypertrace instrument: :all
