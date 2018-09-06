module Hyperstack
  module Transport
    def self.promise_send(request)
      agent = Hyperstack::Transport::RequestAgent.new
      Hyperstack.client_transport_driver.send_request('request' => { agent.id => request })
      agent.promise
    end
  end
end