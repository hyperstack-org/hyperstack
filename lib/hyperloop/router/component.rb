module Hyperloop
  class Router
    class Component
      def self.inherited(base)
        base.include(Hyperloop::Component::Mixin)
        base.include(HyperRouter::ComponentMethods)

        base.class_eval do
          param :match, default: nil
          param :location, default: nil
          param :history, default: nil

          define_method(:match) do
            params.match
          end

          define_method(:location) do
            params.location
          end

          define_method(:history) do
            params.history
          end
        end
      end
    end
  end
end
