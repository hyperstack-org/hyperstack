module ReactiveRecord
  # defines the callbacks for simpler poller to use
  class SynchromeshController < ::ActionController::Base

    def subscribe
      Synchromesh::SimplePoller.subscribe(session.id, try(:acting_user), params[:channel])
    end

    def read
      render json: Synchromesh::SimplePoller.read(session.id)
    end
  end

  Engine.routes.append do
    match 'synchromesh-subscribe',        to: 'synchromesh#subscribe', via: :get
    match 'synchromesh-read/:subscriber', to: 'synchromesh#read',      via: :get
  end
end
