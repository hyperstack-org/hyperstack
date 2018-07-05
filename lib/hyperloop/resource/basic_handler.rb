module Hyperloop
  module Resource
    class BasicHandler
      def process_request(request)
        puts "processing #{request}"
      end
    end
  end
end