class HyperOperation
  class << self
    def regulate_uplink(&block)
      @uplink_regulation = block || proc { true }
    end

    def run_on_server(args)
      hash = _params_wrapper.combine_arg_array(args)
      hash = serialize_params(hash)
      HTTP.post(
        "#{`window.HyperloopEnginePath`}/execute_remote",
        payload: {json: {operation: name, params: hash}.to_json},
        headers: {'X-CSRF-Token' => Hyperloop::ClientDrivers.opts[:form_authenticity_token] }
        )
      .then do |response|
        deserialize_response response.json[:response]
      end.fail do |response|
        Exception.new response.json[:error]
      end
    end

    def serialize_params(hash)
      hash
    end

    def deserialize_params(hash)
      hash
    end

    def serialize_response(hash)
      hash
    end

    def deserialize_response(hash)
      hash
    end

    def serialize_dispatch(hash)
      hash
    end

    def deserialize_dispatch(hash)
      hash
    end
  end
end
