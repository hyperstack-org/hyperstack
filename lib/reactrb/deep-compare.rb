# rubocop:disable Style/FileName
# require 'reactrb/deep-compare' to get 0.9 deep compare behavior
module React
  module Component
    module ShouldComponentUpdate

      def props_changed?(next_params)
        next_params != props
      end

      def call_needs_update(next_params, native_next_state)
        component = self
        next_params.define_singleton_method(:changed?) do
          next_params != props
        end
        next_state = Hash.new(native_next_state)
        next_state.define_singleton_method(:changed?) do
          component.native_state_changed?(native_next_state)
        end
        needs_update?(next_params, next_state)
      end
    end
  end
end
