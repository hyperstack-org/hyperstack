module Hyperstack
  module Internal
    module Router
      module ClassMethods
        def history(*args)
          if args.count.positive?
            @__history_type = args.first
          elsif @__history_type
            @__history ||= send(:"#{@__history_type}_history")
          end
        end

        def location
          Hyperstack::Router::Location.new(`#{history.to_n}.location`)
        end

        # def xrender(container = nil, params = {}, &block)
        #   if container
        #     container = container.type if container.is_a? Hyperstack::Component::Element
        #     select_router do
        #       __hyperstack_component_run_post_render_hooks(
        #         Hyperstack::Internal::Component::RenderingContext.render(container, params) do
        #           instance_eval(&block) if block
        #         end
        #       )
        #     end
        #   else
        #     select_router { __hyperstack_component_run_post_render_hooks(instance_eval(&block)) }
        #   end
        # end
        #
        # def select_router(&block)
        #   if Hyperstack::Component::IsomorphicHelpers.on_opal_server?
        #     prerender_router(&block)
        #   else
        #     render_router(&block)
        #   end
        # end

        #alias route render

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

        # def render_router(&block)
        #   define_method(:__hyperstack_component_render) do
        #     self.class.history :browser unless history
        #
        #     React::Router::Router(history: history.to_n) do
        #       instance_eval(&block)
        #     end
        #   end
        # end
        #
        # def prerender_router(&block)
        #   define_method(:__hyperstack_component_render) do
        #     location = {}.tap do |hash|
        #       pathname, search = IsomorphicMethods.request_fullpath.split('?', 2)
        #       hash[:pathname] = pathname
        #       hash[:search] = search ? "?#{search}" : ''
        #     end
        #
        #     React::Router::StaticRouter(location: location.to_n, context: IsomorphicMethods.ctx) do
        #       instance_eval(&block)
        #     end
        #   end
        # end
      end
    end
  end
end
