module Hyperstack
  module Transport
    class ResponseProcessor
      def self.process_response(response_hash)
        if response_hash.has_key?(:response)
          response_hash[:response].keys.each do |agent_id|
            agent = Hyperstack::Transport::RequestAgent.get(agent_id)
            response_hash[:response][agent_id].keys.each do |class_name|
              "::#{class_name.underscore.camelize}".constantize.process_response(agent.promise, response_hash[:response][agent_id][class_name])
            end
          end
        end
      end
    end
  end
end