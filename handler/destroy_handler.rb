class DestroyHandler
  include Hyperstack::Resource::SecurityGuards

  def process_request(_session_id, current_user, request)
    result = {}

    request.keys.each do |model_name|
      model = guarded_record_class(model_name)
      result[model_name] = {} unless result.has_key?(model_name)
      result[model_name][:instances] = {} unless result[model_name].has_key?(:instances)

      request[model_name]['instances'].keys.each do |id|
        record = begin
          model.find(id)
        rescue ActiveRecord::RecordNotFound # , Neo4j::ActiveNode::Labels::RecordNotFound
          nil
        end
        if record
          destroy_successful = record.destroy

          if destroy_successful
            result[model_name][:instances].merge!(id => { destroyed: true })

            Hyperstack::Resource::PubSub.publish_record(record)
          else
            result[model_name][:instances].merge!(id => { errors:  { 'Destroy failed!' => {}}})
          end
        else
          result[model_name][:instances].merge!(id => { destroyed: true })
        end
      end

    end

    result
  end
end
