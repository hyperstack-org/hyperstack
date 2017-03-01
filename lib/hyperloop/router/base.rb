module Hyperloop
  class Router
    module Base
      def self.included(base)
        base.extend(Router::ClassMethods)
        base.include(Router::ComponentMethods)
      end
    end
  end
end
