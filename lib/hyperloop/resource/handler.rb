module Hyperloop
  module Resource
    module Handler
      def process_request(request)
        result = {}
        request.keys.each do |key|
          handler_const = "Hyperloop::Resource::#{key.camelize}Handler"
          handler = Object.const_get(handler_const)
          result.merge(handler.new.process_request(request[key]))
        end
        result
      end
    end
  end
end