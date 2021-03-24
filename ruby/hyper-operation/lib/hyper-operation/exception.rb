module Mutations
  class ErrorHash
    def self.new_from_error_hash(errors)
			new.tap do |hash|
				errors.each do |key, values|
					hash[key] = ErrorAtom.new(key, values[:symbol], values)
				end
			end
    end
  end
end

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
      def as_json(*)
        errors.as_json
      end

      def initialize(errors)
        unless errors.is_a? Mutations::ErrorHash
          errors = Mutations::ErrorHash.new_from_error_hash(errors)
        end
        super(errors)
      end
    end
  end
end
