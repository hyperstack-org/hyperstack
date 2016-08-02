module ReactiveRecord
  # defines the callbacks for simpler poller to use
  class SynchromeshController < ::ActionController::Base
    def subscribe
      render json: { id: Synchromesh::SimplePoller.subscribe }
    end

    def read
      render json: Synchromesh::SimplePoller.read(params[:subscriber])
    end
  end

  Engine.routes.append do
    match 'synchromesh-subscribe',        to: 'synchromesh#subscribe', via: :get
    match 'synchromesh-read/:subscriber', to: 'synchromesh#read',      via: :get
  end
end
