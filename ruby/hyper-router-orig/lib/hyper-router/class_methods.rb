module HyperRouter
  class NoHistoryError < StandardError; end

  module ClassMethods
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
      @__browser_history ||= React::Router::History.current.create_browser_history
    end

    def hash_history(*args)
      @__hash_history ||= React::Router::History.current.create_hash_history(*args)
    end

    def memory_history(*args)
      @__memory_history ||= React::Router::History.current.create_memory_history(*args)
    end

    def render_router(&block)
      define_method(:render) do
        self.class.history :browser unless history

        React::Router::Router(history: history.to_n) do
          instance_eval(&block)
        end
      end
    end

    def prerender_router(&block)
      define_method(:render) do
        location = {}.tap do |hash|
          pathname, search = IsomorphicMethods.request_fullpath.split('?', 2)
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
