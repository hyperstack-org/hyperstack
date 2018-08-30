class SaveHandler
  include Hyperstack::Resource::Helpers
  include Hyperstack::Resource::SecurityGuards
  include Hyperstack::Gate

  def process_request(session_id, current_user, request)
    result = {}

    request.keys.each do |model_name|
      model = guarded_record_class(model_name)

      request[model_name]['instances'].keys.each do |id|
        record_is_new = id.start_with?('_new_')

        record = if record_is_new
                   model.new
                 else
                   begin
                     # authorize Model.find
                     if Hyperstack.resource_use_authorization
                       authorization_result = authorize(current_user, model.to_s, :find, { id => request[model_name]['instances'][id] })
                       if authorization_result.has_key?(:denied)
                         result.deep_merge!(model_name => { instances: { id => { errors:  { 'Record could not be saved!' => authorization_result[:denied] }}}})
                         next # authorization guard
                       end
                     end
                     model.find(id)
                   rescue ActiveRecord::RecordNotFound # , Neo4j::ActiveNode::Labels::RecordNotFound
                     nil
                   end
                 end

        if record
          # authorize record create, for a new record, or update for a existing one)
          if Hyperstack.resource_use_authorization
            authorization_result = if record_is_new
                                     authorize(current_user, model.to_s, :create, request[model_name]['instances'][id])
                                   else
                                     authorize(current_user, model.to_s, :update, request[model_name]['instances'][id])
                                   end
            if authorization_result.has_key?(:denied)
              result.deep_merge!(model_name => { instances: { id => { errors:  { 'Record could not be saved!' => authorization_result[:denied] }}}})
              next # authorization guard
            end
          end
          request[model_name]['instances'][id]['properties'].delete('id')
          record.assign_attributes(request[model_name]['instances'][id]['properties'])
          if record.save
            if Hyperstack.resource_use_pubsub
              if record_is_new
                Hyperstack::Resource::PubSub.subscribe_record(session_id, record)
              else
                Hyperstack::Resource::PubSub.pub_sub_record(session_id, record)
              end
              Hyperstack::Resource::PubSub.publish_scope(model, :all)
            end

            result.deep_merge!(record.to_transport_hash)
          else
            result.deep_merge!(model_name => { instances: { record.id.to_s => { errors: { 'Record could not be saved!' => '' }}}})
          end
        end

      end
    end
    result
  end
end
