module Hyperloop
  class Router
    module Static
      def self.included(base)
        base.extend(HyperRouter::ClassMethods)
        base.extend(ClassMethods)

        base.include(HyperRouter::InstanceMethods)
        base.include(HyperRouter::ComponentMethods)
      end
    end
  end
end
