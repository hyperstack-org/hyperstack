require 'net/http' unless RUBY_ENGINE == 'opal'

module Hyperstack
  class ServerOp < Operation

    class << self
      include Hyperstack::Component::IsomorphicHelpers

      if RUBY_ENGINE == 'opal'
        if on_opal_client?
          def run(*args)
            hash = _Railway.params_wrapper.combine_arg_array(args)
            hash = serialize_params(hash)
            Hyperstack::HTTP.post(
              "#{`window.HyperstackEnginePath`}/execute_remote",
              payload: {json: {operation: name, params: hash}.to_json},
              headers: headers.merge('X-CSRF-Token' => Hyperstack::ClientDrivers.opts[:form_authenticity_token])
              )
            .then do |response|
              deserialize_response response.json[:response]
            end
            .fail do |response|
              begin
                const_get(response.json[:error_class]).new(response.json[:error])
              rescue
                Exception.new response.json[:error]
              end
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
          Hyperstack::ServerOp.run_from_client(:acting_user, controller, klass_name, *op_params)
        }
      end

      def descendants_map_cache
        # calling descendants alone may take 10ms in a complex app, so better cache it
        @cached_descendants ||= Hyperstack::ServerOp.descendants.map(&:to_s)
      end

      def run_from_client(security_param, controller, operation, params)
        if Rails.env.production?
          # in production everything is eager loaded so ServerOp.descendants is filled and can be used to guard the .constantize
          unless Hyperstack::ServerOp.descendants_map_cache.include?(operation)
            Hyperstack::InternalPolicy.raise_operation_access_violation(:illegal_remote_op_call, "Operation: #{operation} (in production)")
          end
          # however ...
        else
          # ... in development things are autoloaded on demand, thus ServerOp.descendants can be empty or partially filled and above guard
          # would fail legal operations. To prevent this, the class has to be loaded first, what .const_get will take care of, and then
          # its guarded, to achieve similar behaviour as in production. Doing the const_get first, before the guard,
          # would not be safe for production and allow for potential remote code execution!
          begin
            const = Object.const_get(operation)
          rescue NameError
            Hyperstack::InternalPolicy.raise_operation_access_violation(:illegal_remote_op_call, "Operation: #{operation} (const not found)")
          end
          unless const < Hyperstack::ServerOp
            Hyperstack::InternalPolicy.raise_operation_access_violation(:illegal_remote_op_call, "Operation: #{operation} (not a ServerOp subclass)")
          end
        end
        operation.constantize.class_eval do
          if _Railway.params_wrapper.method_defined?(:controller)
            params[:controller] = controller
          elsif !_Railway.params_wrapper.method_defined?(security_param)
            raise AccessViolation.new(:remote_access_not_allowed)
          end
          run(deserialize_params(params))
          .then { |r| return { json: { response: serialize_response(r) } } }
          .fail { |e| return handle_exception(e, operation, params) }
        end
      rescue Exception => e
        handle_exception(e, operation, params)
      end

      def status(e)
        if e.is_a? AccessViolation
          403
        elsif e.is_a? Operation::ValidationException
          400
        else
          500
        end
      end

      def handle_exception(e, operation, params)
        if e.respond_to? :__hyperstack_on_error
          params = params.to_h
          message = []
          message << Pastel.new.red("HYPERSTACK ERROR during #{operation} #{e.inspect}")
          params.each { |param, value| message << "  #{param} => #{value.inspect.truncate(120, separator: '...')}" }
          message << "\n#{e.details}" if e.respond_to? :details
          e.__hyperstack_on_error(operation, params, message.join("\n"))
        end

        { json: { error_class: e.class.to_s, error: e}, status: status(e) }
      end


      def remote(path, *args)
        promise = Promise.new
        uri = URI("#{path}execute_remote_api")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        if uri.scheme == 'https'
          http.use_ssl = true
        end
        request.body = {
          operation: name,
          params: Hyperstack::Operation::ParamsWrapper.combine_arg_array(args)
        }.to_json
        promise.resolve http.request(request)
      rescue Exception => e
        promise.reject e
      end

      def headers
        {}
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
          operation.instance_variable_set(:@_dispatched_channels, []) unless operation.instance_variable_get(:@_dispatched_channels)
          serialized_params = serialize_dispatch(params.to_h)
          [operation.instance_exec(*context, &regulation)].flatten.compact.uniq.each do |channel|
            unless operation.instance_variable_get(:@_dispatched_channels).include?(channel)
              operation.instance_variable_set(:@_dispatched_channels, operation.instance_variable_get(:@_dispatched_channels) << channel)
              Hyperstack.dispatch(channel: Hyperstack::InternalPolicy.channel_to_string(channel), operation: operation.class.name, params: serialized_params)
            end
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
