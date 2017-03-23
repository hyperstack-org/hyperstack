module Hyperloop
  class Router
    module Memory
      module ClassMethods
        def render(&block)
          define_method(:render) do
            React::Router::MemoryRouter() do
              instance_eval(&block)
            end
          end
        end
      end
    end
  end
end
