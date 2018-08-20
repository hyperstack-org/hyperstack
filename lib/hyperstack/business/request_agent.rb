module Hyperstack
  module Business
    class RequestAgent
      def self.agents
        @_agents ||= {}
      end

      attr_accessor :result

      def intitialize
        self.class.agents[object_id] = self
      end
    end
  end
end