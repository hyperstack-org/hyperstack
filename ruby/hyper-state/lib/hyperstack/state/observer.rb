module Hyperstack
  module State
    module Observer
      def observing(immediate_update: false, rendering: false, update_objects: false, &block)
        Internal::State::Mapper.observing(self, immediate_update, rendering, update_objects, &block)
      end

      def update_objects_to_observe
        Internal::State::Mapper.update_objects_to_observe(self)
      end

      def remove
        Internal::State::Mapper.remove
      end
    end
  end
end
