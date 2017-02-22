module Hyperloop
  class AccessViolation < StandardError
    def message
      "Hyperloop::Operation::AccessViolation: #{super}"
    end
  end

  class Operation
    class ValidationException < Mutations::ValidationException
    end
  end

end
