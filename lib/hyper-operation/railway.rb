module Hyperloop
  class Operation
    def self._Railway
      @_railway ||= begin
        if superclass == Operation
          Class.new(Railway)
        else
          Class.new(superclass._Railway).tap do |wrapper|
            [:@validations, :@tracks, :@receivers].each do |var|
              value = superclass._Railway.instance_variable_get(var)
              wrapper.instance_variable_set(var, value && value.dup)
            end
          end
        end
      end
    end
    class Railway
      def initialize(operation)
        @operation = operation
      end
    end
  end
end
