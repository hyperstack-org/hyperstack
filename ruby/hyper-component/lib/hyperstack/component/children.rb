module Hyperstack
  module Component
    class Children
      include Enumerable

      def initialize(children)
        @children = children
      end

      def render
        each(&:render)
      end

      def to_proc
        -> () { render }
      end

      def each(&block)
        return to_enum(__callee__) { length } unless block_given?
        return [] unless length > 0
        collection = []
        %x{
          React.Children.forEach(#{@children}, function(context){
            #{
              element = Element.new(`context`)
              block.call(element)
              collection << element
            }
          })
        }
        collection
      end

      def length
        @length ||= `React.Children.count(#{@children})`
      end
      alias_method :size, :length
    end
  end
end
