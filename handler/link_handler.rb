class LinkHandler
  include Hyperstack::Resource::SecurityGuards

  def process_request(session_id, current_user, request)
    result = {}

    request.keys.each do |model_name|

      model = guarded_record_class(model_name) # security guard
      result[model_name] = {} unless result.has_key?(model_name)
      result[model_name][:instances] = {} unless result[model_name].has_key?(:instances)

      request[model_name]['instances'].keys.each do |id|
        record = begin
          model.find(id)
        rescue ActiveRecord::RecordNotFound
          nil
        end

        if record
          request[model_name]['instances'][id]['relations'].keys.each do |relation_name|

            sym_relation_name = relation_name.to_sym
            relation_type = record.class.reflect_on_association(sym_relation_name)&.macro # security guard

            if relation_type

              request[model_name]['instances'][id]['relations'][relation_name].keys.each do |right_model_name|

                right_model = guarded_record_class(right_model_name) # security guard

                request[model_name]['instances'][id]['relations'][relation_name][right_model_name].keys.each do |right_id|
                  right_record = right_model.find(right_id)

                  if right_record
                    collection = nil
                    relation_type = model.reflections[sym_relation_name].association.type
                    relation_type = model.reflections[relation_name].association.type unless relation_type
                    if %i[belongs_to has_one].include?(relation_type)
                      record.send("#{relation_name}=", right_record)
                      record.save
                    else
                      collection = record.send(relation_name) << right_record
                    end
                    record.touch
                    right_record.touch

                    Hyperstack::Resource::PubSub.pub_sub_relation(session_id, collection, record, relation_name, right_record)
                    Hyperstack::Resource::PubSub.pub_sub_record(session_id, right_record)
                    Hyperstack::Resource::PubSub.pub_sub_record(session_id, record)

                    record_json = record.as_json

                    if record_json.has_key?(model_name)
                      # for neo4j
                      result[model_name][:instances].merge!(id => { properties: record_json[model_name] })
                    else
                      # for active_record
                      result[model_name][:instances].merge!(id => { properties: record_json })
                    end
                  end
                end
              end
            end
          end
        else
          result[model_name][:instances].merge!(errors: { id => { 'Record not found!' => ''}})
        end
      end
    end

    result
  end
end
