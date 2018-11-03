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
  param_accessor_style :both
  class << self
    def inherited(child)
      child.include Hyperstack::Legacy::Store
    end
  end
end
