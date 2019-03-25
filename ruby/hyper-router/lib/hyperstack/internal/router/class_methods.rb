module Hyperstack
  module Internal
    module Router
      module ClassMethods
        def history(*args)
          if args.count.positive?
            @__history_type = args.first
          elsif @__history_type
            @__history ||= send(:"#{@__history_type}_history")
          end
        end

        def location
          Hyperstack::Router::Location.new(`#{history.to_n}.location`)
        end

        private

        def browser_history
          @__browser_history ||= React::Router::History.current.create_browser_history
        end

        def hash_history(*args)
          @__hash_history ||= React::Router::History.current.create_hash_history(*args)
        end

        def memory_history(*args)
          @__memory_history ||= React::Router::History.current.create_memory_history(*args)
        end
      end
    end
  end
end
