module React
  module Component
    module DslInstanceMethods
      def children
        if `#{@native}.props.children==undefined`
          nodes = []
        else
          nodes = [`#{@native}.props.children`].flatten
        end
        class << nodes
          include Enumerable

          def to_n
            self
          end

          def each(&block)
            if block_given?
              %x{
                    React.Children.forEach(#{self.to_n}, function(context){
              #{yield React::Element.new(`context`)}
                    })
              }
              nil
            else
              Enumerator.new(`React.Children.count(#{self.to_n})`) do |y|
                %x{
                      React.Children.forEach(#{self.to_n}, function(context){
                #{y << Element.new(`context`)}
                      })
                }
              end
            end
          end
        end

        nodes
      end

      def params
        @props_wrapper
      end

      def props
        Hash.new(`#{@native}.props`)
      end

      def refs
        Hash.new(`#{@native}.refs`)
      end

      def state
        @state_wrapper ||= StateWrapper.new(@native, self)
      end
    end
  end
end
