module Hyperloop
  class Router
    class Component
      include React::Component
      include ComponentMethods

      def self.inherited(base)
        base.class_eval do
          param :match, default: nil
        end
      end
    end
  end
end
