module ReactiveRecord

  module Pry

    def self.rescued(e)
      if defined?(PryRescue) && e.instance_variable_defined?(:@rescue_bindings) && !e.is_a?(Hyperloop::AccessViolation)
        ::Pry::rescued(e)
      end
    end

  end

end
