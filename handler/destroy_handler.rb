class DestroyHandler
  include Hyperstack::Resource::SecurityGuards
  include Hyperstack::Gate

  def process_request(_session_id, current_user, request)
    result = {}

    request.keys.each do |model_name|
      model = guarded_record_class(model_name) # security guard

      request[model_name]['instances'].keys.each do |id|

        # authorize Model.find
        if Hyperstack.resource_use_authorization
          authorization_result = authorize(current_user, model.to_s, :find, { id => request[model_name]['instances'][id] })
          if authorization_result.has_key?(:denied)
            result.deep_merge!(model_name => { instances: { id => { errors:  { 'Destroy failed!' => authorization_result[:denied] }}}})
            next # authorization guard
          end
        end

        record = begin
                   model.find(id)
                 rescue ActiveRecord::RecordNotFound # , Neo4j::ActiveNode::Labels::RecordNotFound
                   nil
                 end
        if record

          # authorize record.destroy
          if Hyperstack.resource_use_authorization
            authorization_result = authorize(current_user, model.to_s, :destroy, record)
            if authorization_result.has_key?(:denied)
              result.deep_merge!(model_name => { instances: { id => { errors:  { 'Destroy failed!' => authorization_result[:denied] }}}})
              next # authorization guard
            end
          end

          destroy_successful = record.destroy

          if destroy_successful
            result.deep_merge!(model_name => { instances: { id => { destroyed: true }}})
            Hyperstack::Resource::PubSub.publish_record(record) if Hyperstack.resource_use_pubsub
          else
            result.deep_merge!(model_name => { instances: { id => { errors:  { 'Destroy failed!' => {}}}}})
          end
        else
          result.deep_merge!(model_name => { instances: { id => { destroyed: true }}})
        end
      end

    end

    result
  end
end
