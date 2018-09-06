module Hyperstack
  module Transport
    class RequestAgent
      def self.agents
        @_agents ||= {}
      end

      def self.get(object_id)
        agents.delete(object_id.to_s)
      end

      attr_reader :id
      attr_reader :promise

      def initialize
        @id = object_id.to_s
        self.class.agents[@id] = self
        @promise = Promise.new
      end
    end
  end
end