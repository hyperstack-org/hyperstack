module Hyperstack
  module Vis
    module Timeline
      class Component
        include Hyperstack::Vis::Timeline::Mixin
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