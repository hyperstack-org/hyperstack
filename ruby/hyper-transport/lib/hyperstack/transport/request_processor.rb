module Hyperstack
  module Transport
    module RequestProcessor
      def process_request(session_id, current_user, request)
        result = { response: {} }

        if request.has_key?('request')
          request['request'].keys.each do |agent_id|

            request['request'][agent_id].keys.each do |key|
              handler = "::#{key.underscore.camelize}Handler".constantize
              if handler
                result[:response][agent_id] = handler.new.process_request(session_id, current_user, request['request'][agent_id][key])
              else
                result[:response][agent_id] = { error: { key => "No such handler!"}}
              end
            end

          end
        else
          result[:response] = 'No such thing!'
        end

        result
      end
    end
  end
end