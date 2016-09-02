module ReactiveRecord

  Engine.routes.append do

    class SynchromeshController < ::ApplicationController

      def subscribe
        session.delete 'synchromesh-dummy-init' unless session.id
        puts "subscribe to #{params[:channel]} for acting_user = #{acting_user} session = #{session.id}"
        Synchromesh::SimplePoller.subscribe(session.id, try(:acting_user), params[:channel])
        puts "success!"
        render :nothing => true
      rescue
        puts "failed"
        render nothing: true, status: :unauthorized
      end

      def read
        puts "read for acting_user = #{acting_user} session = #{session.id}"
        data = Synchromesh::SimplePoller.read(session.id)
        puts "here is the data: #{data}"
        render json: data
      rescue Exception => e
        binding.pry
      end
    end unless defined? SynchromeshController

    match 'synchromesh-subscribe/:channel', to: 'synchromesh#subscribe', via: :get
    match 'synchromesh-read',               to: 'synchromesh#read',      via: :get
  end
end
