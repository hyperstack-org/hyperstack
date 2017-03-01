module Hyperloop
  class Router
    module Memory
      def self.included(base)
        base.extend(ClassMethods)
        base.include(Router::ComponentMethods)
      end
    end
  end
end
