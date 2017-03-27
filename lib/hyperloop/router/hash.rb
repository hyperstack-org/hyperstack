module Hyperloop
  class Router
    module Hash
      def self.included(base)
        base.extend(HyperRouter::ClassMethods)
        base.history(:hash)

        base.include(HyperRouter::InstanceMethods)
        base.include(HyperRouter::ComponentMethods)
      end
    end
  end
end
