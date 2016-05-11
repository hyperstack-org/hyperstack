module ReactiveRecord

  class SyncromeshController < ::ActionController::Base

    def subscribe
      render json: {id: Syncromesh::SimplePoller.subscribe}
    end

    def read
      render json: Syncromesh::SimplePoller.read(params[:subscriber])
    end
  end
  
end
