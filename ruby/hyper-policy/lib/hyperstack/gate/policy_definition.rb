module Hyperstack
  module Gate
    module PolicyDefinition
      def self.included(base)
        base.include(Hyperstack::Gate::InstanceMethods)
        base.extend(Hyperstack::Gate::ClassMethods)
      end
    end
  end
end