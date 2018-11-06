module Hyperstack
  module Router
    module Helpers
      def match
        if @__hyperstack_component_params_wrapper.param_accessor_style != :hyperstack
          params.match
        else
          @Match
        end
      end

      def location
        if @__hyperstack_component_params_wrapper.param_accessor_style != :hyperstack
          params.location
        else
          @Location
        end
      end

      def history
        if @__hyperstack_component_params_wrapper.param_accessor_style != :hyperstack
          params.history
        else
          @History
        end
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
