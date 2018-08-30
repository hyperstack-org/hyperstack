module Hyperstack
  class Operation
    class SecurityError < StandardError
    end

    module SecurityGuards
      def guarded_record_class(model_name)
        raise Hyperstack::Operation::SecurityError unless self.class.valid_operation_class_params.include?(model_name) # guard
        model_name.camelize.constantize
      end
    end
  end
end
