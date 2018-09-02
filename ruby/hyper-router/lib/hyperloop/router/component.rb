module Hyperloop
  class Router
    class Component
      class << self
        def inherited(base)
          base.include(Mixin)
        end
      end
    end
  end
end
