module HyperRouter
  class NoHistoryError < StandardError; end

  module ClassMethods
    def initial_path(*args)
      name = args[0].is_a?(Hash) ? args[0].first[0] : args[0]

      define_method(:initial_path) do
        params.send(:"#{name}")
      end

      param(*args)
    end

    alias prerender_path initial_path

    def history(*args)
      if args.count > 0
        @__history_type = args.first
      elsif @__history_type
        @__history ||= send(:"#{@__history_type}_history")
      end
    end

    def location
      Location.new(`#{history.to_n}.location`)
    end

    def route(&block)
      if React::IsomorphicHelpers.on_opal_server?
        prerender_router(&block)
      else
        render_router(&block)
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

    def render_router(&block)
      define_method(:render) do
        raise(HyperRouter::NoHistoryError, 'A history must be defined') unless history

        React::Router::Router(history: history.to_n) do
          instance_eval(&block)
        end
      end
    end

    def prerender_router(&block)
      define_method(:render) do
        location = {}.tap do |hash|
          pathname, search = (respond_to?(:initial_path) ? initial_path : '').split('?', 2)
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
