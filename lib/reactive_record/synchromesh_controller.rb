module ReactiveRecord

  Engine.routes.append do

    class SynchromeshController < ::ApplicationController

      def subscribe
        session.delete 'synchromesh-dummy-init' unless session.id
        Synchromesh::SimplePoller.subscribe(session.id, try(:acting_user), params[:channel])
        render :nothing => true
      rescue
        render nothing: true, status: :unauthorized
      end

      def read
        data = Synchromesh::SimplePoller.read(session.id)
        render json: data
      end

      def pusher_auth
        channel = params[:channel_name].gsub(/^#{Regexp.quote(Synchromesh.channel)}\-/,'')
        Synchromesh::InternalPolicy.regulate_connection(acting_user, channel)
        response = Synchromesh.pusher.authenticate(params[:channel_name], params[:socket_id])
        Synchromesh::PusherChannels.add_connection(channel)
        render json: response
      rescue Exception => e
        render nothing: true, status: :unauthorized
      end

    end unless defined? SynchromeshController

    match 'synchromesh-subscribe/:channel', to: 'synchromesh#subscribe',   via: :get
    match 'synchromesh-read',               to: 'synchromesh#read',        via: :get
    match 'synchromesh-pusher-auth',        to: 'synchromesh#pusher_auth', via: :post
  end
end
