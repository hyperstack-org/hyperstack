module Hyperstack
  module Policy
    module PolicyDefinition
      def self.included(base)
        base.include(Hyperstack::Policy::InstanceMethods)
        base.extend(Hyperstack::Policy::ClassMethods)
      end
    end
  end
end