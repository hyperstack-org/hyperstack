module Hyperloop
  class Store
    class << self
      def inherited(child)
        child.include(Mixin)
      end
    end
    def initialize
      init_store
    end
  end
end
