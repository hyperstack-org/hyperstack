module HyperRouter
  module ClassMethods
    def prerender_path(*args)
      name = args[0].is_a?(Hash) ? args[0].first[0] : args[0]

      define_method(:prerender_path) do
        params.send(:"#{name}")
      end

      param(*args)
    end

    def history(*args)
      if args.count > 0
        @__history = send(:"#{args.first}_history")
      else
        @__history
      end
    end

    def location
      Location.new(`#{history.to_n}.location`)
    end

    def route(&block)
      if React::IsomorphicHelpers.on_opal_client?
        render_router(&block)
      else
        prerender_router(&block)
      end
    end

    private

    def browser_history
      React::Router::History.current.create_browser_history
    end

    def hash_history(*args)
      React::Router::History.current.create_hash_history(*args)
    end

    def memory_history(*args)
      React::Router::History.current.create_memory_history(*args)
    end

    def prerender_router(&block)
      define_method(:render) do
        location = {}.tap do |hash|
          pathname, search = (respond_to?(:prerender_path) ? prerender_path : '').split('?', 2)
          hash[:pathname] = pathname
          hash[:search] = search ? "?#{search}" : ''
        end

        React::Router::StaticRouter(location: location.to_n, context: {}.to_n) do
          instance_eval(&block)
        end
      end
    end
  end
end
