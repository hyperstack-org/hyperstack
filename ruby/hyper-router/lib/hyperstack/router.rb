module Hyperstack
  module Router
    class NoHistoryError < StandardError; end

    def __hyperstack_router_wrapper(&block)
      if Hyperstack::Component::IsomorphicHelpers.on_opal_server?
        ->() { __hyperstack_prerender_router(&block) }
      else
        ->() { __hyperstack_render_router(&block) }
      end
    end

    def __eval_block(block)
      result = instance_eval(&block)
      if result.is_a?(String) ||
         (result.respond_to?(:acts_as_string?) && result.acts_as_string?)
        # hyper-mesh DummyValues respond to acts_as_string, and must
        # be converted to spans INSIDE the parent, otherwise the waiting_on_resources
        # flag will get set in the wrong context
        result = Hyperstack::Internal::Component::RenderingContext
                 .render(:span) { result.to_s }
      end
      result
    end

    def __hyperstack_render_router(&block)
      instance_eval do
        self.class.history :browser unless history
        React::Router::Router(history: history.to_n) do
          __eval_block(block)
        end
      end
    end

    def __hyperstack_prerender_router(&block)
      instance_eval do
        pathname, search = Hyperstack::Internal::Router::IsomorphicMethods.request_fullpath.split('?', 2)
        location = { pathname: pathname, search: search ? "?#{search}" : '' }.to_n
        React::Router::StaticRouter(
          location: location,
          context: Hyperstack::Internal::Router::IsomorphicMethods.ctx
        ) do
          __eval_block(block)
        end
      end
    end

    def self.included(base)
      base.extend(Hyperstack::Internal::Router::ClassMethods)

      base.include(Hyperstack::Internal::Router::Helpers)

      base.class_eval do

        def history
          self.class.history
        end

        def location
          self.class.location
        end

        after_mount do
          @_react_router_unlisten = history.listen do |location, _action|
            Hyperstack::Internal::State::Mapper.mutated! Hyperstack::Router::Location
          end
        end

        before_unmount do
          @_react_router_unlisten.call if @_react_router_unlisten
        end
      end

    end
  end
end
