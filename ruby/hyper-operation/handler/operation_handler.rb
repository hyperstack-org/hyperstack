class OperationHandler
  include Hyperstack::Operation::SecurityGuards
  include Hyperstack::Policy if Hyperstack.operation_use_authorization

  def process_request(_session_id, current_user, request)
    result = {}

    request.keys.each do |operation_operation_name|
      result[operation_operation_name] = {} unless result.has_key?(operation_operation_name)

      operation_operation = guarded_operation_class(operation_operation_name)

      request[operation_operation_name].keys.each do |agent_object_id|
        parsed_params = Oj.load(request[operation_operation_name][agent_object_id], symbol_keys: true)

        if Hyperstack.operation_use_authorization
          authorization_result = authorize(current_user, operation_operation, :run, parsed_params)
          if authorization_result.has_key?(:denied)
            result[operation_operation_name][agent_object_id] = { errors: { authorization_result[:denied] => '' }}
            next # authorization guard
          end
        end

        operation_operation.run(*parsed_params).then do |operation_result|
          result[operation_operation_name][agent_object_id] = operation_result
        end
      end
    end

    result
  end
end