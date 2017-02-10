module HyperStore
  class Base
    class << self
      def inherited(child)
        child.include(HyperStore)
      end
    end
  end
end
