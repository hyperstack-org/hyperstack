module Hyperloop
  class Router
    module Hash
      module ClassMethods
        def route(&block)
          define_method(:render) do
            React::Router::DOM::HashRouter() do
              instance_eval(&block)
            end
          end
        end
      end
    end
  end
end
