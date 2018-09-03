module Hyperstack
  module Transport
    module RequestProcessor
      def process_request(session_id, current_user, request)
        result = {}
        request.keys.each do |key|
          # TODO check safety
          handler_const = "::#{key.underscore.camelize}Handler"
          handler = handler_const.camelize.constantize
          if handler
            result.merge!(handler.new.process_request(session_id, current_user, request[key]))
          else
            result.merge!(error: { key => "No such handler!"})
          end
        end
        result
      end
    end
  end
end