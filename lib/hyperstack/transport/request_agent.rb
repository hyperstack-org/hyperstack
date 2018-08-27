module Hyperstack
  module Transport
    class RequestAgent
      def self.agents
        @_agents ||= {}
      end

      def self.get(object_id)
        agents.delete(object_id.to_s)
      end

      attr_accessor :result
      attr_accessor :errors

      def intitialize
        self.class.agents[object_id.to_s] = self
      end
    end
  end
end