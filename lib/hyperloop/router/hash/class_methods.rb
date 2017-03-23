module Hyperloop
  class Router
    module Hash
      module ClassMethods
        def render(&block)
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
