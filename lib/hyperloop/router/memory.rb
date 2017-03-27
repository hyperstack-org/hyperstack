module Hyperloop
  class Router
    module Memory
      def self.included(base)
        base.extend(HyperRouter::ClassMethods)
        base.history(:memory)

        base.include(HyperRouter::InstanceMethods)
        base.include(HyperRouter::ComponentMethods)
      end
    end
  end
end
