module Hyperloop
  class Router
    module Base
      module ClassMethods
        def render_router(&block)
          define_method(:render) do
            if respond_to?(:history)
              React::Router::Router(history: history.to_n) do
                instance_eval(&block)
              end
            else
              React::Router::MemoryRouter(location: { pathname: '/' }.to_n) do
                instance_eval(&block)
              end
            end
          end
        end
      end
    end
  end
end
