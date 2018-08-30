module Hyperloop
  module Vis
    module Network
      class Component
        include Hyperloop::Vis::Network::Mixin
        def self.inherited(base)
          base.class_eval do
            param vis_data: nil
            param options: nil
          end
        end
      end
    end
  end
end