module Hyperstack
  module State
    module Observer
      def observe(immediate_update: false, rendering: false, &block)
        Internal::State.Mapper.observe(self, immediate_update, rendering, &block)
      end

      def update_objects_to_observe
        Internal::State.Mapper.update_objects_to_observe(self)
      end

      def remove
        Internal::State.Mapper.update_states_to_observe(self)
      end
    end
  end
end
