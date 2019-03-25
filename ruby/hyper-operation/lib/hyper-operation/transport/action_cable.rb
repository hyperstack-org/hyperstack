module ApplicationCable
  class Channel < ActionCable::Channel::Base; end
  class Connection < ActionCable::Connection::Base; end
end

module Hyperstack
  class ActionCableChannel < ApplicationCable::Channel
    class << self
      def subscriptions
        @subscriptions ||= Hash.new { |h, k| h[k] = 0 }
      end
    end

    def inc_subscription
      self.class.subscriptions[params[:hyperstack_channel]] =
        self.class.subscriptions[params[:hyperstack_channel]] + 1
    end

    def dec_subscription
      self.class.subscriptions[params[:hyperstack_channel]] =
        self.class.subscriptions[params[:hyperstack_channel]] - 1
    end

    def subscribed
      session_id = params["client_id"]
      authorization = Hyperstack.authorization(params["salt"], params["hyperstack_channel"], session_id)
      if params["authorization"] == authorization
        inc_subscription
        stream_from "hyperstack-#{params[:hyperstack_channel]}"
      else
        reject
      end
    end

    def unsubscribed
      Hyperstack::Connection.disconnect(params[:hyperstack_channel]) if dec_subscription == 0
    end
  end
end
