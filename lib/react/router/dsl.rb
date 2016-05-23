module React
  class Router
    class DSL

      def self.build_routes(*args, &block)
        evaluate_children(*args, &block)[0]
      end

      def self.evaluate_children(*args, &children)
        [[], nil].tap do | new_routes |
          if children
            saved_routes, @routes = [@routes, new_routes]
            @routes << children.call(*args)
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

      def self.children_to_n(children)
        children.collect { |e| e.to_json.to_n }
      end

    end
  end
end
