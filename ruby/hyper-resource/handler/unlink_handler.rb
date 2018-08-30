class UnlinkHandler
  include Hyperstack::Resource::Helpers
  include Hyperstack::Resource::SecurityGuards
  include Hyperstack::Policy

  def process_request(session_id, current_user, request)
    result = {}

    request.keys.each do |model_name|

      model = guarded_record_class(model_name) # security guard

      request[model_name]['instances'].keys.each do |id|

        # authorize Model.find
        if Hyperstack.resource_use_authorization
          authorization_result = authorize(current_user, model.to_s, :find, { id => request[model_name]['instances'][id] })
          if authorization_result.has_key?(:denied)
            result.deep_merge!(model_name => { instances: { id => { errors:  { 'Unlink failed!' => authorization_result[:denied] }}}})
            next # authorization guard
          end
        end

        record = begin
                   model.find(id)
                 rescue ActiveRecord::RecordNotFound # , Neo4j::ActiveNode::Labels::RecordNotFound
                   nil
                 end

        if record
          request[model_name]['instances'][id]['relations'].keys.each do |relation_name|
            sym_relation_name = relation_name.to_sym

            relation_type = record.class.reflect_on_association(sym_relation_name)&.macro # security guard
            if relation_type # security guard

              request[model_name]['instances'][id]['relations'][relation_name].keys.each do |right_model_name|

                right_model = guarded_record_class(right_model_name) # security guard

                request[model_name]['instances'][id]['relations'][relation_name][right_model_name]['instances'].keys.each do |right_id|

                  # authorize Model.find
                  if Hyperstack.resource_use_authorization
                    authorization_result = authorize(current_user, right_model.to_s, :find, { right_id => request[model_name]['instances'][id]['relations'][relation_name][right_model_name]['instances'][right_id] })
                    if authorization_result.has_key?(:denied)
                      result.deep_merge!(model_name => { instances: { id => { errors:  { 'Unlink failed!' => authorization_result[:denied] }}}})
                      next # authorization guard
                    end
                  end

                  right_record = begin
                                   right_model.find(right_id)
                                 rescue ActiveRecord::RecordNotFound # , Neo4j::ActiveNode::Labels::RecordNotFound
                                   nil
                                 end

                  collection = nil

                  if right_record

                    # authorize record unlink relation
                    if Hyperstack.resource_use_authorization
                      authorization_result = authorize(current_user, model.to_s, "#{relation_name}_unlink", [record, right_record])
                      if authorization_result.has_key?(:denied)
                        result.deep_merge!(model_name => { instances: { id => { errors:  { 'Unlink failed!' => authorization_result[:denied] }}}})
                        next # authorization guard
                      end
                    end

                    if %i[belongs_to has_one].include?(relation_type)
                      record.send("#{relation_name}=", nil)
                      record.save
                    else
                      record.send(sym_relation_name).delete(right_record)
                      collection = record.send(sym_relation_name)
                    end

                    record.touch
                    right_record.touch

                    if Hyperstack.resource_use_pubsub
                      Hyperstack::Resource::PubSub.pub_sub_relation(session_id, collection, record, relation_name, right_record)
                      Hyperstack::Resource::PubSub.pub_sub_record(session_id, right_record)
                      Hyperstack::Resource::PubSub.pub_sub_record(session_id, record)
                    end

                    result.deep_merge!(record.to_transport_hash)
                  end

                end
              end
            else
              result.deep_merge!(model_name => { instances: { id => { errors: { relation_name => 'No such relation!' }}}})
            end
          end
        else
          result.deep_merge!(model_name => { instances: { errors: { id => { 'Record not found!' => ''}}}})
        end
      end
    end

    result
  end
end
