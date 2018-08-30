module Hyperstack
  module Params
    module InstanceMethods
      def params
        @params ||= self.class.validator.props_wrapper.new(self)
      end
    end
  end
end
