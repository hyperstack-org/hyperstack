class SendToAll < Hyperloop::ServerOp
  param acting_user: nil, nils: true
  param :message
  param fred: ''
  dispatch_to { Hyperloop::Application }
end
