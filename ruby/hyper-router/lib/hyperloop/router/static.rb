module Hyperloop
  class Router
    module Static
      module ClassMethods
        def route(&block)
          prerender_router(&block)
        end
      end

      def self.included(base)
        base.extend(HyperRouter::ClassMethods)
        base.extend(ClassMethods)

        base.include(HyperRouter::InstanceMethods)
        base.include(HyperRouter::ComponentMethods)
      end
    end
  end
end
