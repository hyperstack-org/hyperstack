module Hyperstack
  module State
    class Variable
      def initialize(name = nil, &initializer)
        @name = name
        return unless initializer
        self.state = object.send(:"instance_#{initializer.lambda? ? :exec : :eval}", &initializer)
      end

      def name
        name || original_to_s
      end

      alias original_to_s to_s

      def to_s
        if @name
          "<State::Variable:#{@name} value = #{@state}>"
        else
          original_to_s.gsub(/>$/, " value = #{@state}")
        end
      end

      def inspect
        if @name
          "<State::Variable:#{@name} value = #{@state.inspect}>"
        else
          original_to_s.gsub(/>$/, " value = #{@state.inspect}")
        end
      end

      def state
        Internal::State::Context.observed!(self)
        @state
      end

      def mutated!
        Internal::State::Context.mutated!(self)
        self
      end

      def mutate
        if block_given?
          yield.tap { mutated! }
        else
          @observer ||= Internal::State::Observer.new(self)
        end
      end

      def state=(new_value)
        mutate { @state = new_value } if @state != new_value
      end

      def toggle!
        self.state = !state
      end

      def set?
        !!state
      end

      def clear?
        !state
      end

      def nil?
        state.nil?
      end

      def zero?
        state.zero?
      end

      def observed?
        Internal::State::Context.observed? self
      end

      def __non_reactive_read__
        @state
      end

      class << self
        # wrap all execution that may set or get states in a block so we
        # know which observer is executing

        def set_state_context_to(observer, immediate_update: false, rendering: nil, &block)
          Internal::State::Context.set_state_context_to(observer, immediate_update, rendering, &block)
        end

        # Call after each component updates. (in the after_update/after_mount callbacks)

        def update_states_to_observe(observer = current_observer)
          Internal::State::Context.update_states_to_observe(observer)
        end

        # call after component is unmounted

        def remove
          Internal::State::Context.remove
        end

        # use bulk_update to delay notifications until after the current event
        # completes processing.

        def bulk_update(&block)
          Internal::State::Context.bulk_update(&block)
        end
      end
    end
  end
end
