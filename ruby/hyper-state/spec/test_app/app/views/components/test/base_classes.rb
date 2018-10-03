class HyperStore
  class << self
    def inherited(child)
      child.include(Hyperstack::Component::Mixin)
    end
  end
  # def initialize
  #   init_store
  # end
end

class HyperComponent
  include Hyperstack::Component::Mixin
end
