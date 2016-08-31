module ReactiveRecord
  # defines the callbacks for simpler poller to use
  class SynchromeshController < ::ActionController::Base

    def subscribe
      session.delete 'synchromesh-dummy-init' unless session.id
      Synchromesh::SimplePoller.subscribe(session.id, try(:acting_user), params[:channel])
      render :nothing => true
    end

    def read
      render json: Synchromesh::SimplePoller.read(session.id)
    end
  end

  Engine.routes.append do
    match 'synchromesh-subscribe/:channel', to: 'synchromesh#subscribe', via: :get
    match 'synchromesh-read',               to: 'synchromesh#read',      via: :get
  end
end
