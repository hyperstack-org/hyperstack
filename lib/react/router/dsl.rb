module React
  class Router
    class DSL

      def self.evaluate_children(&children)
        [[], nil].tap do | new_routes |
          if children
            saved_routes, @routes = [@routes, new_routes]
            yield
            @routes = saved_routes
          end
        end
      end

      def self.add_element(element)
        @routes[0] <<  element
      end

      def self.set_index(index)
        @routes[1] = index
      end

    end
  end
end
