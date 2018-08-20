module Hyperstack
  class Business
    def self.inherited(child)
      child.include(Hyperstack::Business::Mixin)
    end
  end
end