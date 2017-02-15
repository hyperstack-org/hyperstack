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

    def regulate_dispatch(*args, &regulation)
      _regulate_dispatch(nil, args, &regulation) if RUBY_ENGINE != 'opal'
    end

    def _regulate_dispatch(context, args=[], &regulation)
      if args.count == 0 && regulation.nil?
        raise "must provide either a list of channel classes or a block to regulate_dispatch"
      elsif args.count > 0 && regulation
        raise "cannot provide both a list of channel classes and a block to regulate_dispatch"
      end
      regulation ||= proc { args }
      on_dispatch do |params, operation|
        serialized_params = serialize_dispatch(params.to_h)
        [operation.instance_exec(*context, &regulation)].flatten.compact.each do |channel|
          Hyperloop.dispatch(channel: channel, operation: name, params: serialized_params)
        end
      end if RUBY_ENGINE != 'opal'
    end

    def dispatch_from_server(params_hash)
      params = _params_wrapper.new(deserialize_dispatch(params_hash)).lock
      receivers.each { |receiver| receiver.call params }
    end
  end
end
