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
      if RUBY_ENGINE != 'opal'
        if args.count == 0 && regulation.nil?
          raise "must provide either a list of channel classes or a block to regulate_dispatch"
        elsif args.count > 0 && regulation
          raise "cannot provide both a list of channel classes and a block to regulate_dispatch"
        end
        regulation = -> () { args } if args.count > 0
        on_dispatch do |params|
          data = { operation: self.name, params: serialize_dispach(params.to_h) }
          [*instance_eval(&regulation)].flatten.each do |channel|
            Hyperloop.dispatch(channel,  data)
          end
        end
      end
    end

    def dispatch_from_server(params_hash)
      params = _params_wrapper.new(deserialize_dispatch(params_hash)).lock
      receivers.each { |receiver| receiver.call params }
    end
  end
end
