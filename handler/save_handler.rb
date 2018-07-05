module Hyperloop
  module Resource
    class SaveHandler
      def process_request(request)
        result = {}

        request.each_key do |model_name|
          model = guarded_record_class(model_name)
          record = model.find(request[model_name]['id'])
          if record && record.save
            result.merge!(model_name => { request[model_name] => { instances: { record.id.to_s => { properties: { updated_at: record.updated_at }}}}})
          else
            result.merge!(model_name => { request[model_name] => { instances: { record.id.to_s => false }}})
          end
        end

        result
      end
    end
  end
end