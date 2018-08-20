class BusinessHandler
  include Hyperloop::Business::SecurityGuards

  # enable authorization if needed, depends on hyper-gate, also see below
  # include Hyperloop::Gate

  def process_request(_session_id, current_user, request)
    result = {}

    request.keys.each do |business_operation_name|
      result[business_operation_name] = {} unless result.has_key?(business_operation_name)

      business_operation = guarded_business_class(business_operation_name)

      # enable authorization if needed, depends on hyper-gate, also see above
      # authorize(current_user, business_operation, :run)

      request[business_operation_name].keys.each do |params|
        parsed_params = Oj.load(params, symbol_keys: true)
        business_operation.run(parsed_params).then do |operation_result|
          result[business_operation_name][params] = operation_result
        end
      end
    end

    result
  end
end