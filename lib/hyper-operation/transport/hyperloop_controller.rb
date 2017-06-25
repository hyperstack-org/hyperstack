module Hyperloop
  ::Hyperloop::Engine.routes.append do
    Hyperloop.initialize_policies

    module ::WebConsole
      class Middleware
      private
        def acceptable_content_type?(headers)
          Mime::Type.parse(headers['Content-Type'] || '').first == Mime[:html]
        end
      end
    end if defined? ::WebConsole::Middleware

    module ::Rails
      module Rack
        class Logger < ActiveSupport::LogSubscriber
          unless method_defined? :pre_hyperloop_call
            alias pre_hyperloop_call call
            def call(env)
              if !Hyperloop.opts[:noisy] && env['HTTP_X_HYPERLOOP_SILENT_REQUEST']
                Rails.logger.silence do
                  pre_hyperloop_call(env)
                end
              else
                pre_hyperloop_call(env)
              end
            end
          end
        end
      end
    end if defined?(::Rails::Rack::Logger)

    class HyperloopController < ::ApplicationController

      protect_from_forgery except: [:console_update, :execute_remote_api]

      def client_id
        params[:client_id]
      end

      before_action do
        session.delete 'hyperloop-dummy-init' unless session.id
      end

      def channels(user = acting_user, session_id = session.id)
        Hyperloop::AutoConnect.channels(session_id, user)
      end

      def can_connect?(channel, user = acting_user)
        Hyperloop::InternalPolicy.regulate_connection(
          user,
          Hyperloop::InternalPolicy.channel_to_string(channel)
        )
        true
      rescue
        nil
      end

      def view_permitted?(model, attr, user = acting_user)
        !!model.check_permission_with_acting_user(user, :view_permitted?, attr)
      rescue
        nil
      end

      def viewable_attributes(model, user = acting_user)
        model.attributes.select { |attr| view_permitted?(model, attr, user) }
      end

      [:create, :update, :destroy].each do |op|
        define_method "#{op}_permitted?" do |model, user = acting_user|
          begin
            !!model.check_permission_with_acting_user(user, "#{op}_permitted?".to_sym)
          rescue
            nil
          end
        end
      end

      def debug_console
        if Rails.env.development?
          render inline: "<style>div#console {height: 100% !important;}</style>\n".html_safe
          #  "<div>additional helper methods: channels, can_connect? "\
          #  "viewable_attributes, view_permitted?, create_permitted?, "\
          #  "update_permitted? and destroy_permitted?</div>\n".html_safe
          console
        else
          head :unauthorized
        end
      end

      def subscribe
        channel = params[:channel].gsub('==', '::')
        Hyperloop::InternalPolicy.regulate_connection(try(:acting_user), channel)
        root_path = request.original_url.gsub(/hyperloop-subscribe.*$/, '')
        Hyperloop::Connection.open(channel, client_id, root_path)
        head :ok
      rescue Exception
        head :unauthorized
      end

      def read
        root_path = request.original_url.gsub(/hyperloop-read.*$/, '')
        data = Hyperloop::Connection.read(client_id, root_path)
        render json: data
      end

      def pusher_auth
        channel = params[:channel_name].gsub(/^#{Regexp.quote(Hyperloop.channel)}\-/,'').gsub('==', '::')
        Hyperloop::InternalPolicy.regulate_connection(acting_user, channel)
        response = Hyperloop.pusher.authenticate(params[:channel_name], params[:socket_id])
        render json: response
      rescue Exception => e
        head :unauthorized
      end

      def action_cable_auth
        channel = params[:channel_name].gsub(/^#{Regexp.quote(Hyperloop.channel)}\-/,'')
        Hyperloop::InternalPolicy.regulate_connection(acting_user, channel)
        salt = SecureRandom.hex
        authorization = Hyperloop.authorization(salt, channel, client_id)
        render json: {authorization: authorization, salt: salt}
      rescue Exception
        head :unauthorized
      end

      def connect_to_transport
        root_path = request.original_url.gsub(/hyperloop-connect-to-transport.*$/, '')
        render json: Hyperloop::Connection.connect_to_transport(params[:channel], client_id, root_path)
      end

      def execute_remote
        parsed_params = JSON.parse(params[:json]).symbolize_keys
        render ServerOp.run_from_client(
          :acting_user,
          self,
          parsed_params[:operation],
          parsed_params[:params].merge(acting_user: acting_user)
        )
      end

      def execute_remote_api
        params.require(:params).permit!
        parsed_params = params[:params].to_h.symbolize_keys
        raise AccessViolation unless parsed_params[:authorization]
        render ServerOp.run_from_client(:authorization, self, params[:operation], parsed_params)
      end

      def console_update # TODO this should just become an execute-remote-api call
        authorization = Hyperloop.authorization(params[:salt], params[:channel], params[:data][1][:broadcast_id]) #params[:data].to_json)
        return head :unauthorized if authorization != params[:authorization]
        Hyperloop::Connection.send_to_channel(params[:channel], params[:data])
        head :no_content
      rescue
        head :unauthorized
      end

      def server_up
        head :no_content
      end

    end unless defined? Hyperloop::HyperloopController

    match 'execute_remote',
          to: 'hyperloop#execute_remote', via: :post
    match 'execute_remote_api',
          to: 'hyperloop#execute_remote_api', via: :post

    # match 'hyperloop-subscribe',
    #       to: 'hyperloop#subscribe', via: :get
    # match 'hyperloop-read/:subscriber',
    #       to: 'hyperloop#read',      via: :get
    match 'hyperloop-subscribe/:client_id/:channel',
          to: 'hyperloop#subscribe', via: :get
    match 'hyperloop-read/:client_id',
          to: 'hyperloop#read', via: :get
    match 'hyperloop-pusher-auth',
          to: 'hyperloop#pusher_auth', via: :post
    match 'hyperloop-action-cable-auth/:client_id/:channel_name',
          to: 'hyperloop#action_cable_auth', via: :post
    match 'hyperloop-connect-to-transport/:client_id/:channel',
          to: 'hyperloop#connect_to_transport', via: :get
    match 'console',
          to: 'hyperloop#debug_console', via: :get
    match 'console_update',
          to: 'hyperloop#console_update', via: :post
    match 'server_up',
          to: 'hyperloop#server_up', via: :get
  end
end
