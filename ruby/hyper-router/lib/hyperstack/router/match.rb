module Hyperstack
  module Router
    class Match
      include Native::Wrapper

      def initialize(native)
        @native = native
      end

      def to_n
        @native
      end

      alias_native :params
      alias_native :is_exact, :isExact
      alias_native :path
      alias_native :url
    end
  end
end
