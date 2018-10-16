module Hyperstack
  module Internal
    module State
      class Mutatable
        def initialize(state)
          @state = state
        end

        def method_missing(method, *args, &block)
          super unless respond_to? method
          @state.mutate { |value| value.send(method, *args, &block) }
        end

        def respond_to?(method, *args)
          [:call, :to_proc].include?(method) || @state.__non_reactive_read__.respond_to?(method, *args)
        end

        def call(new_value)
          @state.state = new_value
        end

        def to_proc
          lambda { |arg = @value| @state.state = arg }
        end
      end
    end
  end
end
