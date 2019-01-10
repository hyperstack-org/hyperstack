module Hyperstack
  class AccessViolation < StandardError

    attr_accessor :details

    def initialize(message = nil, details = nil)
      super("Hyperstack::AccessViolation#{':' + message.to_s if message}")
      @details = details
    end

    def __hyperstack_on_error(operation, params, fmted_message)
      Hyperstack.on_error(operation, self, params, fmted_message)
    end
  end

  class Operation
    class ValidationException < Mutations::ValidationException
    end
  end

end
