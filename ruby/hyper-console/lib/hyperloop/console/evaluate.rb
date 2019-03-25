module Hyperloop
  module Console
    class Evaluate < Hyperloop::ServerOp
      param acting_user: nil, nils: true
      param :target_id
      param :sender_id
      param :context
      param string: nil
      dispatch_to { Hyperloop::Application }
    end

    class Response < Hyperloop::ServerOp
      param acting_user: nil, nils: true
      param :target_id
      param :kind
      param :message
      dispatch_to { Hyperloop::Application }
    end
  end
end
