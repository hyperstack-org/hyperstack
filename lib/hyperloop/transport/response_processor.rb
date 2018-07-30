module Hyperloop
  module Transport
    class ResponseProcessor
      def self.process_response(response_hash)
        response_hash.keys.each do |key|
          key.underscore.camelize.constantize.process_response(response_hash[key])
        end
      end
    end
  end
end