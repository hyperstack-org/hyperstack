module ReactiveRecord

  Engine.routes.append do

    class SynchromeshController < ::ApplicationController

      before_action do |controller|
        session.delete 'synchromesh-dummy-init' unless session.id
      end

      def subscribe
        Synchromesh::InternalPolicy.regulate_connection(try(:acting_user), params[:channel])
        Synchromesh::PolledConnection.new(session.id, params[:channel])
        render nothing: true
      rescue
        render nothing: true, status: :unauthorized
      end

      def read
        data = Synchromesh::PolledConnection.read(session.id)
        render json: data
      end

      def pusher_auth
        channel = params[:channel_name].gsub(/^#{Regexp.quote(Synchromesh.channel)}\-/,'')
        Synchromesh::InternalPolicy.regulate_connection(acting_user, channel)
        response = Synchromesh.pusher.authenticate(params[:channel_name], params[:socket_id])
        render json: response
      rescue Exception => e
        render nothing: true, status: :unauthorized
      end

      def pusher_connect
        Synchromesh::PusherChannels.add_connection(params[:channel])
        render json: Synchromesh::PolledConnection.disconnect(session.id, params[:channel])
      end

    end unless defined? SynchromeshController

    match 'synchromesh-subscribe/:channel',          to: 'synchromesh#subscribe',      via: :get
    match 'synchromesh-read',                        to: 'synchromesh#read',           via: :get
    match 'synchromesh-pusher-auth',                 to: 'synchromesh#pusher_auth',    via: :post
    match 'synchromesh-pusher-connect/:channel',     to: 'synchromesh#pusher_connect', via: :get
  end
end
