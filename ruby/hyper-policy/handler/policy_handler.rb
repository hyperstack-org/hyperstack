class PolicyHandler
  include Hyperstack::Policy

  def process_request(_session_id, current_user, request)
    result = { hyperstack_gate: {} }

    request.keys.each do |agent_object_id|
      class_name = request[agent_object_id]['class_name']
      action = request[agent_object_id]['action']
      policy_context = Oj.load(request[agent_object_id]['action']['policy_context'], symbol_keys: true)

      authorization_result = authorize(current_user, class_name, action, *policy_context)

      result[:hyper_stack_gate_processor][agent_object_id] = authorization_result
    end

    result
  end
end