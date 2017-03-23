module Hyperloop
  class Router
    module Browser
      module ClassMethods
        def render_router(&block)
          define_method(:render) do
            React::Router::DOM::BrowserRouter() do
              instance_eval(&block)
            end
          end
        end
      end
    end
  end
end
