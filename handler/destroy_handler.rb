module Hyperloop
  module Resource
    class DestroyHandler
      def process_request(request)
        result = {}

        request.each_key do |model_name|
          model = guarded_record_class(model_name)
          if request[model_name].has_key?('instances')
            request[model_name]['instances'].each_key do |id|
              record = model.find(id)
              result.merge!(model_name => { instances: { id: (record ? record.destroy : false) }})
            end
          end
        end

        result
      end
    end
  end
end