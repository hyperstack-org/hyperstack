module Hyperstack
  class AccessViolation < StandardError
    def message
      "Hyperstack::Operation::AccessViolation: #{super}"
    end
  end

  class Operation
    class ValidationException < Mutations::ValidationException
    end
  end

end
