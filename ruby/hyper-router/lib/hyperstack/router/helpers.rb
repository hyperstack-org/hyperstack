module Hyperstack
  module Router
    module Helpers
      def match
        @match
      end

      def location
        @location
      end

      def history
        @history
      end

      def self.included(base)
        base.include(Hyperstack::Internal::Router::Helpers)

        base.class_eval do
          param :match, default: nil
          param :location, default: nil
          param :history, default: nil
        end
      end
    end
  end
end
