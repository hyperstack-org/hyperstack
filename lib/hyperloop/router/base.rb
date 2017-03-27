module Hyperloop
  class Router
    module Base
      def self.included(base)
        base.extend(HyperRouter::ClassMethods)

        base.include(HyperRouter::InstanceMethods)
        base.include(HyperRouter::ComponentMethods)
      end
    end
  end
end
