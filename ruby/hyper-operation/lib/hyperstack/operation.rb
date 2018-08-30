module Hyperstack
  class Operation
    def self.inherited(child)
      child.include(Hyperstack::Operation::Mixin)
    end
  end
end