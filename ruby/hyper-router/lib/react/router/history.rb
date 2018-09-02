module React
  class Router
    class History
      include Native

      def self.current
        new(`History`)
      end

      def initialize(native)
        @native = native
      end

      def to_n
        @native
      end

      alias_native :create_browser_history, :createBrowserHistory
      alias_native :create_hash_history, :createHashHistory
      alias_native :create_location, :createLocation
      alias_native :create_memory_history, :createMemoryHistory
      alias_native :create_path, :createPath
    end
  end
end
