module Hyperstack
  ::Hyperstack::Engine.routes.append do
    Hyperstack.initialize_policies

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
          unless method_defined? :pre_hyperstack_call
            alias pre_hyperstack_call call
            def call(env)
              if Hyperstack.transport == :simple_poller && env['PATH_INFO'] && env['PATH_INFO'].include?('/hyperstack-read/')
                Rails.logger.silence do
                  pre_hyperstack_call(env)
                end
              else
                pre_hyperstack_call(env)
              end
            end
          end
        end
      end
    end if defined?(::Rails::Rack::Logger)

    class HyperstackController < ::ApplicationController

      protect_from_forgery except: [:console_update, :execute_remote_api]

      def client_id
        params[:client_id]
      end

      before_action do
        session.delete 'hyperstack-dummy-init' unless session.id
      end

      def session_channel
        "Hyperstack::Session-#{session.id}"
      end

      def regulate(channel)
        unless channel == session_channel # "Hyperstack::Session-#{client_id.split('-').last}"
          Hyperstack::InternalPolicy.regulate_connection(try(:acting_user), channel)
        end
        channel
      end

      def channels(user = acting_user, session_id = session.id)
        Hyperstack::AutoConnect.channels(session_id, user)
      end

      def can_connect?(channel, user = acting_user)
        Hyperstack::InternalPolicy.regulate_connection(
          user,
          Hyperstack::InternalPolicy.channel_to_string(channel)
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
        channel = regulate params[:channel].gsub('==', '::')
        root_path = request.original_url.gsub(/hyperstack-subscribe.*$/, '')
        Hyperstack::Connection.open(channel, client_id, root_path)
        head :ok
      rescue Exception
        head :unauthorized
      end

      def read
        root_path = request.original_url.gsub(/hyperstack-read.*$/, '')
        data = Hyperstack::Connection.read(client_id, root_path)
        render json: data
      end

      def pusher_auth
        raise unless Hyperstack.transport == :pusher
        channel = regulate params[:channel_name].gsub(/^#{Regexp.quote(Hyperstack.channel)}\-/,'').gsub('==', '::')
        response = Hyperstack.pusher.authenticate(params[:channel_name], params[:socket_id])
        render json: response
      rescue Exception => e
        head :unauthorized
      end

      def action_cable_auth
        raise unless Hyperstack.transport == :action_cable
        channel = regulate params[:channel_name].gsub(/^#{Regexp.quote(Hyperstack.channel)}\-/,'')
        salt = SecureRandom.hex
        authorization = Hyperstack.authorization(salt, channel, client_id)
        render json: {authorization: authorization, salt: salt}
      rescue Exception
        head :unauthorized
      end

      def connect_to_transport
        root_path = request.original_url.gsub(/hyperstack-connect-to-transport.*$/, '')
        render json: Hyperstack::Connection.connect_to_transport(params[:channel], client_id, root_path)
      rescue Exception => e
        render status: :service_unavailable, json: {error: e}
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
        raise unless Rails.env.development?
        authorization = Hyperstack.authorization(params[:salt], params[:channel], params[:data][1][:broadcast_id]) #params[:data].to_json)
        return head :unauthorized if authorization != params[:authorization]
        Hyperstack::Connection.send_to_channel(params[:channel], params[:data])
        head :no_content
      rescue
        head :unauthorized
      end

      def server_up
        head :no_content
      end

    end unless defined? Hyperstack::HyperstackController

    match 'execute_remote',
          to: 'hyperstack#execute_remote', via: :post
    match 'execute_remote_api',
          to: 'hyperstack#execute_remote_api', via: :post

    # match 'hyperstack-subscribe',
    #       to: 'hyperstack#subscribe', via: :get
    # match 'hyperstack-read/:subscriber',
    #       to: 'hyperstack#read',      via: :get
    match 'hyperstack-subscribe/:client_id/:channel',
          to: 'hyperstack#subscribe', via: :get
    match 'hyperstack-read/:client_id',
          to: 'hyperstack#read', via: :get
    match 'hyperstack-pusher-auth',
          to: 'hyperstack#pusher_auth', via: :post
    match 'hyperstack-action-cable-auth/:client_id/:channel_name',
          to: 'hyperstack#action_cable_auth', via: :post
    match 'hyperstack-connect-to-transport/:client_id/:channel',
          to: 'hyperstack#connect_to_transport', via: :get
    match 'console',
          to: 'hyperstack#debug_console', via: :get
    match 'console_update',
          to: 'hyperstack#console_update', via: :post
    match 'server_up',
          to: 'hyperstack#server_up', via: :get
  end
end
