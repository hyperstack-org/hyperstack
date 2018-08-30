require "react/children"

module React
  module Component
    module DslInstanceMethods
      def children
        Children.new(`#{@native}.props.children`)
      end

      def props
        Hash.new(`#{@native}.props`)
      end

      def refs
        Hash.new(`#{@native}.refs`)
      end
    end
  end
end
