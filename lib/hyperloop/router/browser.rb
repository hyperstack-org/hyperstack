module Hyperloop
  class Router
    module Browser
      def self.included(base)
        base.extend(HyperRouter::ClassMethods)
        base.extend(ClassMethods)

        base.include(HyperRouter::ComponentMethods)
      end
    end
  end
end
