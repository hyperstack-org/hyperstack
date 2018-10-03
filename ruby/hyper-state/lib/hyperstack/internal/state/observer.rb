module Hyperstack
  module Internal
    class State
      class Observer
        def initialize(state)
          @state = state
        end

        def method_missing(method, *args, &block)
          value = @state.__non_reactive_read__
          value.send(method, *args, &block).tap { @state.state = value }
        end

        def respond_to?(method, *args)
          if [:call, :to_proc].include? method
            true
          else
            @value.respond_to? method, *args
          end
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
