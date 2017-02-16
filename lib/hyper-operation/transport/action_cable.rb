module ApplicationCable
  class Channel < ActionCable::Channel::Base; end
  class Connection < ActionCable::Connection::Base; end
end

module Hyperloop
  class ActionCableChannel < ApplicationCable::Channel
    class << self
      def subscriptions
        @subscriptions ||= Hash.new { |h, k| h[k] = 0 }
      end
    end

    def inc_subscription
      self.class.subscriptions[params[:hyperloop_channel]] =
        self.class.subscriptions[params[:hyperloop_channel]] + 1
    end

    def dec_subscription
      self.class.subscriptions[params[:hyperloop_channel]] =
        self.class.subscriptions[params[:hyperloop_channel]] - 1
    end

    def subscribed
      session_id = params["client_id"]
      authorization = Hyperloop.authorization(params["salt"], params["hyperloop_channel"], session_id)
      if params["authorization"] == authorization
        inc_subscription
        stream_from "hyperloop-#{params[:hyperloop_channel]}"
      else
        reject
      end
    end

    def unsubscribed
      Hyperloop::Connection.disconnect(params[:hyperloop_channel]) if dec_subscription == 0
    end
  end
end
