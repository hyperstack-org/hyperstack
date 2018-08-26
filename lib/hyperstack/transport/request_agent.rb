module Hyperstack
  module Transport
    class RequestAgent
      def self.agents
        @_agents ||= {}
      end

      attr_accessor :result
      attr_accessor :errors

      def intitialize
        self.class.agents[object_id] = self
      end
    end
  end
end