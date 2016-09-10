module ReactiveRecord

  Engine.routes.append do

    class SynchromeshController < ::ApplicationController

      before_action do |controller|
        session.delete 'synchromesh-dummy-init' unless session.id
      end

      def subscribe
        Synchromesh::InternalPolicy.regulate_connection(try(:acting_user), params[:channel])
        Synchromesh::Connection.new(params[:channel], session.id)
        render nothing: true
      rescue
        render nothing: true, status: :unauthorized
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
      rescue Exception => e
        render nothing: true, status: :unauthorized
      end

      def connect_to_transport
        render json: Synchromesh::Connection.connect_to_transport(params[:channel], session.id)
      end

    end unless defined? SynchromeshController

    match 'synchromesh-subscribe/:channel',            to: 'synchromesh#subscribe',            via: :get
    match 'synchromesh-read',                          to: 'synchromesh#read',                 via: :get
    match 'synchromesh-pusher-auth',                   to: 'synchromesh#pusher_auth',          via: :post
    match 'synchromesh-connect-to-transport/:channel', to: 'synchromesh#connect_to_transport', via: :get
  end
end
