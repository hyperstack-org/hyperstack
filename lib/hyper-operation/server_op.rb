module Hyperloop
  class ServerOp < Operation

    class << self
      include React::IsomorphicHelpers

      if RUBY_ENGINE == 'opal'
        if on_opal_client?
          def run(*args)
            hash = _Railway.params_wrapper.combine_arg_array(args)
            hash = serialize_params(hash)
            HTTP.post(
              "#{`window.HyperloopEnginePath`}/execute_remote",
              payload: {json: {operation: name, params: hash}.to_json},
              headers: {'X-CSRF-Token' => Hyperloop::ClientDrivers.opts[:form_authenticity_token] }
              )
            .then do |response|
              deserialize_response response.json[:response]
            end
            .fail do |response|
              Exception.new response.json[:error]
            end
          end
        elsif on_opal_server?
          def run(*args)
            promise = Promise.new
            response = internal_iso_run(name, args)
            if response[:json][:response]
              promise.resolve(response[:json][:response])
            else
              promise.reject Exception.new response[:json][:error]
            end
            promise
          end
        end
      end

      isomorphic_method(:internal_iso_run) do |f, klass_name, op_params|
        f.send_to_server(klass_name, op_params)
        f.when_on_server {
          Hyperloop::ServerOp.run_from_client(:acting_user, controller, klass_name, *op_params)
        }
      end
    
      def run_from_client(security_param, controller, operation, params)
        operation.constantize.class_eval do
          if _Railway.params_wrapper.method_defined?(:controller)
            params[:controller] = controller
          elsif !_Railway.params_wrapper.method_defined?(security_param)
            raise AccessViolation
          end
          run(params)
          .then { |r| return { json: { response: serialize_response(r) } } }
          .fail do |e|
            ::Rails.logger.debug "\033[0;31;1mERROR: Hyperloop::ServerOp failed when running #{operation} with params \"#{params}\": #{e}\033[0;30;21m"
            return { json: { error: e }, status: 500 }
          end
        end
      rescue Exception => e
        ::Rails.logger.debug "\033[0;31;1mERROR: Hyperloop::ServerOp exception caught when running #{operation} with params \"#{params}\": #{e}\033[0;30;21m"
        { json: { error: e }, status: 500 }
      end

      def remote(path, *args)
        promise = Promise.new
        uri = URI("#{path}execute_remote_api")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request.body = {
          operation: name,
          params: Hyperloop::Operation::ParamsWrapper.combine_arg_array(args)
        }.to_json
        promise.resolve http.request(request)
      rescue Exception => e
        promise.reject e
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

      def dispatch_to(*args, &regulation)
        _dispatch_to(nil, args, &regulation) if RUBY_ENGINE != 'opal'
      end

      def _dispatch_to(context, args=[], &regulation)
        if args.count == 0 && regulation.nil?
          raise "must provide either a list of channel classes or a block to regulate_dispatch"
        elsif args.count > 0 && regulation
          raise "cannot provide both a list of channel classes and a block to regulate_dispatch"
        end
        regulation ||= proc { args }
        on_dispatch do |params, operation|
          serialized_params = serialize_dispatch(params.to_h)
          [operation.instance_exec(*context, &regulation)].flatten.compact.uniq.each do |channel|
            Hyperloop.dispatch(channel: Hyperloop::InternalPolicy.channel_to_string(channel), operation: operation.class.name, params: serialized_params)
          end
        end
      end if RUBY_ENGINE != 'opal'

      def dispatch_from_server(params_hash)
        params = _Railway.params_wrapper.new(deserialize_dispatch(params_hash)).lock
        _Railway.receivers.each { |receiver| receiver.call params }
      end
    end
  end

  class ControllerOp < ServerOp
    inbound :controller
    alias pre_controller_op_method_missing method_missing
    def method_missing(name, *args, &block)
      if params.controller.respond_to? name
        params.controller.send(name, *args, &block)
      else
        pre_controller_op_method_missing(name, *args, &block)
      end
    end
  end
end
