module Hyperstack
  module Record
    class Base
      def self.inherited(base)
        base.include(Hyperstack::Record::Mixin)
      end
    end
  end
end