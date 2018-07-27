module Hyperloop
  module Resource
    module Handler
      def process_request(request)
        result = {}
        request.keys.each do |key|
          # TODO check safety
          handler_const = "#{key.underscore.camelize}Handler"
          handler = Object.const_get(handler_const)
          if handler
            result.merge!(handler.new.process_request(request[key]))
          else
            result.merge!(error: { key => "No such handler!"})
          end
        end
        result
      end
    end
  end
end