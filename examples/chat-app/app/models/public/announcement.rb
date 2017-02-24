class Announcement < Hyperloop::ServerOp
  # should be able to say always_allow_connection HERE... instead its in the policy file...
  # and setting a connection for a ServerOp should automatically dispatch to that connection..
  # a few bugs to fix...
  param :acting_user, nils: true
  param :message
  dispatch_to { Application }
end
