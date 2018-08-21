class SaveHandler
  include Hyperstack::Resource::SecurityGuards

  def process_request(request)
    result = {}

    request.keys.each do |model_name|
      model = guarded_record_class(model_name)
      result[model_name] = {} unless result.has_key?(model_name)
      result[model_name][:instances] = {} unless result[model_name].has_key?(:instances)

      request[model_name].keys.each do |id|
        record = if id.start_with?('_new_')
                   model.new
                 else
                   model.find(id)
                 end
        if record
          request[model_name][id]['properties'].delete('id')
          record.assign_attributes(request[model_name][id]['properties'])
          if record.save
            record_hash = {}
            record_hash[model_name] = {} unless record_hash.has_key?(model_name)
            record_json = record.as_json
            if record_json.has_key?(model)
              # for neo4j
              record_hash[model_name].merge!(record.id => { properties: record_json[model_name] })
            else
              # for active_record
              record_hash[model_name].merge!(record.id => { properties: record_json })
            end
            result[model_name][:instances].merge!(record.id.to_s => record_hash)
          else
            result[model_name][:instances].merge!(record.id.to_s => { errors: "Record could not be saved!" })
          end
        end
      end
    end
    result
  end
end
