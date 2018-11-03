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

class HyperComponent
  include Hyperstack::Component
  param_accessor_style :legacy
  class << self
    def inherited(child)
      child.include Hyperstack::Legacy::Store
    end
  end
end
