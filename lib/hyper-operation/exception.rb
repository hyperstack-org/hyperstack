class HyperOperation
  class ValidationException < Mutations::ValidationException
  end
end

module Hyperloop
  class AccessViolation < StandardError
    def message
      "HyperOperation::AccessViolation: #{super}"
    end
  end
end
