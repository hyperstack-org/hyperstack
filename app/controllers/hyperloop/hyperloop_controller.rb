
module Hyperloop
  class HyperloopController < ::ApplicationController
    #skip_before_action :verify_authenticity_token
    def execute_remote
      render run_from_client(acting_user, JSON.parse(params[:json]).symbolize_keys)
    end

    def run_from_client(acting_user, params)
      params[:operation].constantize.class_eval do
        raise Hyperloop::AccessViolation unless @uplink_regulation.call(acting_user)
        run(deserialize_params(params[:params]))
        .then { |r| return { json: { response: serialize_response(r) } } }
        .fail { |e| return { json: { error: e}, status: 500 } }
      end
    rescue Exception => e
      { json: {error: e}, status: 500 }
    end
  end
end
