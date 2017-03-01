module Hyperloop
  class Router
    module ClassMethods
      def history(history_type)
        define_method(:history) do
          self.class.send(:"#{history_type}_history")
        end
      end

      def route(&block)
        define_method(:render) do
          # If history has not been defined, just use memory history
          unless respond_to?(:history)
            raise('A history must be defined when using the low-level Router component.')
          end

          React::Router::Router(history: history.to_n) do
            instance_eval(&block)
          end
        end
      end

      def browser_history
        React::Router::History.current.create_browser_history
      end

      def hash_history
        React::Router::History.current.create_hash_history
      end

      def memory_history
        React::Router::History.current.create_memory_history
      end
    end
  end
end
