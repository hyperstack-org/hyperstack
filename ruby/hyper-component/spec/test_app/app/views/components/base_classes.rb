class HyperStore
  class << self
    def inherited(child)
      child.include Hyperstack::Legacy::Store
    end
  end
  # def initialize
  #   init_store
  # end
end

module Hyperloop
  class Component
    include Hyperstack::Component
    class << self
      def inherited(child)
        child.include Hyperstack::Legacy::Store
      end
    end
  end
end

class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
end
