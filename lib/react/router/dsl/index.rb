module React
  class Router
    class DSL
      class Index < React::Router::DSL::Route

        def save_element
          DSL.set_index self
        end

      end
    end
  end
end
