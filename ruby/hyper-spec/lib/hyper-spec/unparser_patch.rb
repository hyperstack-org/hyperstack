module Unparser
  class Emitter
    # Emitter for send
    class Send < self
      def local_variable_clash?
        selector =~ /^[A-Z]/ || local_variable_scope.local_variable_defined_for_node?(node, selector)
      end
    end
  end
end
