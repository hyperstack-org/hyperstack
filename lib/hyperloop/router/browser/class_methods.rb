module Hyperloop
  class Router
    module Browser
      module ClassMethods
        def route(&block)
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
