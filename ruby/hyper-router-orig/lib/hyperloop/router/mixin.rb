module Hyperloop
  class Router
    module Mixin
      class << self
        def included(base)
          base.include(Hyperloop::Component)
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
end
