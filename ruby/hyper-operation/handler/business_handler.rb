class BusinessHandler
  include Hyperstack::Business::SecurityGuards
  include Hyperstack::Gate if Hyperstack.business_use_authorization

  def process_request(_session_id, current_user, request)
    result = {}

    request.keys.each do |business_operation_name|
      result[business_operation_name] = {} unless result.has_key?(business_operation_name)

      business_operation = guarded_business_class(business_operation_name)

      request[business_operation_name].keys.each do |agent_object_id|
        parsed_params = Oj.load(request[business_operation_name][agent_object_id], symbol_keys: true)

        if Hyperstack.business_use_authorization
          authorization_result = authorize(current_user, business_operation, :run, parsed_params)
          if authorization_result.has_key?(:denied)
            result[business_operation_name][agent_object_id] = { errors: { authorization_result[:denied] => '' }}
            next # authorization guard
          end
        end

        business_operation.run(*parsed_params).then do |operation_result|
          result[business_operation_name][agent_object_id] = operation_result
        end
      end
    end

    result
  end
end