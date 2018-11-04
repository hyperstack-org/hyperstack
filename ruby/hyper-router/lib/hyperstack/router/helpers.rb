module Hyperstack
  module Router
    module Helpers
      def match
        if @__hyperstack_component_params_wrapper.param_accessor_style != :hyperstack
          params.match
        else
          @match
        end
      end

      def location
        if @__hyperstack_component_params_wrapper.param_accessor_style != :hyperstack
          params.location
        else
          @location
        end
      end

      def history
        if @__hyperstack_component_params_wrapper.param_accessor_style != :hyperstack
          params.history
        else
          @history
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
