class HyperstackGateProcessor
  def process_response(response)
    response.keys.each do |agent_object_id|
      agent = Hyperstack::Gate::RequestAgent.agents.delete(agent_object_id)
      agent.result = response[agent_object_id]
    end
  end
end