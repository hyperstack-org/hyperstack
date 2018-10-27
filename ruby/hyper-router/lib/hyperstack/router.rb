module Hyperstack
  module Router
    class NoHistoryError < StandardError; end
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
            Hyperstack::Internal::State::Mapper.observed! Hyperstack::Router::Location
          end
        end

        before_unmount do
          @_react_router_unlisten.call if @_react_router_unlisten
        end
      end

    end
  end
end
