require 'operations/send_to_all' if RUBY_ENGINE == 'opal'
module Operations
  class NestedSendToAll < ::SendToAll
    # param :message
    # step SendToAll
  end
end
