module Hyperloop
  module Vis
    class Component
      include Hyperloop::Vis::Mixin
      def self.inherited(base)
        base.class_eval do
          param data: nil
        end
      end
    end
  end
end