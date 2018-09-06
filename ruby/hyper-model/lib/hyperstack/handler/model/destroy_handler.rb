module Hyperstack
  module Handler
    module Model
      class DestroyHandler
        include Hyperstack::Model::SecurityGuards

        def process_request(_session_id, current_user, request)
          result = {}

          request.keys.each do |model_name|
            model = guarded_record_class(model_name) # security guard

            request[model_name]['instances'].keys.each do |id|

              # authorize Model.find
              if Hyperstack.authorization_driver
                authorization_result = Hyperstack.authorization_driver.authorize(current_user, model.to_s, :find, { id => request[model_name]['instances'][id] })
                if authorization_result.has_key?(:denied)
                  result.deep_merge!(model_name => { instances: { id => { errors:  { 'Destroy failed!' => authorization_result[:denied] }}}})
                  next # authorization guard
                end
              end

              record = model.hyperstack_orm_driver.find(id)
              return result.deep_merge!(model_name => { instances: { id => { destroyed: true }}}) if record.nil?

              # authorize record.destroy
              if Hyperstack.authorization_driver
                authorization_result = Hyperstack.authorization_driver.authorize(current_user, model.to_s, :destroy, record)
                if authorization_result.has_key?(:denied)
                  result.deep_merge!(model_name => { instances: { id => { errors:  { 'Destroy failed!' => authorization_result[:denied] }}}})
                  next # authorization guard
                end
              end

              destroy_successful = model.hyperstack_orm_driver.destroy(record)

              if destroy_successful
                result.deep_merge!(model_name => { instances: { id => { destroyed: true }}})
                # Hyperstack::Model::PubSub.publish_record(record) if Hyperstack.model_use_pubsub
              else
                result.deep_merge!(model_name => { instances: { id => { errors:  { 'Destroy failed!' => {}}}}})
              end
            end

          end

          result
        end
      end
    end
  end
end

