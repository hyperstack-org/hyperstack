module React
  class Router
    class DSL

      class TransitionContext

        def initialize(opts={})
          @prev_state = Hash.new opts[:prev_state]
          @next_state = Hash.new opts[:next_state]
          @replace = opts[:replace]
          @location = Hash.new opts[:loation]
        end

        attr_reader :prev_state
        attr_reader :next_state
        attr_reader :location

        def replace(url)
          `#{@replace}(#{url})`
        end

        def promise
          @promise ||= Promise.new
        end

      end

    end
  end
end
