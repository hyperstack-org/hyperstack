module React
  class Router
    class Component
      include React::Component
      include Methods

      def self.inherited(base)
        base.class_eval do
          param :match, default: nil
        end
      end
    end
  end
end
