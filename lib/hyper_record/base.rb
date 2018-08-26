module HyperRecord
  class Base
    def self.inherited(base)
      base.include(HyperRecord::Mixin)
    end
  end
end