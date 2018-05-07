module Hyperloop
  class Router
    module Base
      def self.included(base)
        base.extend(HyperRouter::ClassMethods)

        base.include(HyperRouter::InstanceMethods)
        base.include(HyperRouter::ComponentMethods)

        base.class_eval do
          after_mount do
            @_react_router_unlisten = history.listen do |location, _action|
              React::State.set_state(HyperRouter, :location, location)
            end
          end

          before_unmount do
            @_react_router_unlisten.call if @_react_router_unlisten
          end
        end
      end
    end
  end
end
