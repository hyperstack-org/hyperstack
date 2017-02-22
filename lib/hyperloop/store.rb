module Hyperloop
  class Store
    class << self
      def inherited(child)
        child.include(Mixin)
      end
    end
  end
end
