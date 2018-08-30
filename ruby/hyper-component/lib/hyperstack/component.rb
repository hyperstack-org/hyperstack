module Hyperstack
  class Component
    def self.inherited(child)
      child.include(Mixin)
    end
  end
end