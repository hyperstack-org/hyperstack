module Hyperloop
  class AccessViolation < StandardError
    def message
      "Hyperloop::Operation::AccessViolation: #{super}"
    end
  end
end
