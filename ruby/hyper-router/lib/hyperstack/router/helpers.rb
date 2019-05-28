module Hyperstack
  module Router
    module Helpers
      def match
        @_match_param
      end

      def location
        @_location_param
      end

      def history
        @_history_param
      end

      def self.included(base)
        base.include(Hyperstack::Internal::Router::Helpers)

        base.class_eval do
          param :match,    default: nil, alias: :_match_param
          param :location, default: nil, alias: :_location_param
          param :history,  default: nil, alias: :_history_param
        end
      end
    end
  end
end
