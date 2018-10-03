module Hyperstack
  module Internal
    class State
      ALWAYS_UPDATE_STATE_AFTER_RENDER = Hyperstack.on_client? # if on server then we don't wait to update the state
      @rendering_level = 0

      include InstanceMethods
      extend  ClassMethods
      extend  WrapperMethods
    end
  end
end
