module Hyperstack
  module Vis
    module Graph2d
      class Component
        include Hyperstack::Vis::Graph2d::Mixin
        def self.inherited(base)
          base.class_eval do
            param items: nil
            param groups: nil
            param options: nil
          end
        end
      end
    end
  end
end