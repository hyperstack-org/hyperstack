module ReactiveRecord

  Engine.routes.append do

    class SynchromeshController < ::ApplicationController

      before_action do |controller|
        session.delete 'synchromesh-dummy-init' unless session.id
      end

      def subscribe
        Synchromesh::InternalPolicy.regulate_connection(try(:acting_user), params[:channel])
        Synchromesh::Connection.new(params[:channel], session.id)
        head :ok
      rescue Exception
        head :unauthorized
      end

      def read
        data = Synchromesh::Connection.read(session.id)
        render json: data
      end

      def pusher_auth
        channel = params[:channel_name].gsub(/^#{Regexp.quote(Synchromesh.channel)}\-/,'')
        Synchromesh::InternalPolicy.regulate_connection(acting_user, channel)
        response = Synchromesh.pusher.authenticate(params[:channel_name], params[:socket_id])
        render json: response
      rescue Exception
        head :unauthorized
      end

      def action_cable_auth
        channel = params[:channel_name].gsub(/^#{Regexp.quote(Synchromesh.channel)}\-/,'')
        Synchromesh::InternalPolicy.regulate_connection(acting_user, channel)
        salt = SecureRandom.hex
        authorization = Synchromesh.authorization(salt, channel, session.id)
        render json: {authorization: authorization, salt: salt}
      rescue Exception
        head :unauthorized
      end

      def connect_to_transport
        render json: Synchromesh::Connection.connect_to_transport(params[:channel], session.id)
      end

    end unless defined? SynchromeshController

    match 'synchromesh-subscribe/:channel',            to: 'synchromesh#subscribe',            via: :get
    match 'synchromesh-read',                          to: 'synchromesh#read',                 via: :get
    match 'synchromesh-pusher-auth',                   to: 'synchromesh#pusher_auth',          via: :post
    match 'synchromesh-action-cable-auth/:channel_name',             to: 'synchromesh#action_cable_auth',    via: :post
    match 'synchromesh-connect-to-transport/:channel', to: 'synchromesh#connect_to_transport', via: :get
  end
end
