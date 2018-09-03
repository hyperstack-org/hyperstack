module Hyperstack
  module Handler
    module Model
      class CreateHandler
        include Hyperstack::Model::SecurityGuards

        def process_request(session_id, current_user, request)
          result = {}

          request.keys.each do |model_name|
            model = guarded_record_class(model_name)

            request[model_name]['instances']['new'].keys.each do |some_id|

              # authorize record create
              if Hyperstack.authorization_driver
                authorization_result = Hyperstack.authorization_driver.authorize(current_user, model.to_s, :create, request[model_name]['instances'][id])
                if authorization_result.has_key?(:denied)
                  result.deep_merge!(model_name => { instances: { id => { errors:  { 'Record could not be created!' => authorization_result[:denied] }}}})
                  next # authorization guard
                end
              end

              if model.hyperstack_orm_driver.create(request[model_name]['instances'][id]['properties'])
                # if Hyperstack.model_use_pubsub
                #   if record_is_new
                #     Hyperstack::Model::PubSub.subscribe_record(session_id, record)
                #   else
                #     Hyperstack::Model::PubSub.pub_sub_record(session_id, record)
                #   end
                #   Hyperstack::Model::PubSub.publish_scope(model, :all)
                # end

                result.deep_merge!(record.to_transport_hash)
              else
                result.deep_merge!(model_name => { instances: { record.id.to_s => { errors: { 'Record could not be creaed!' => '' }}}})
              end
            end

          end
          result
        end
      end
    end
  end
end