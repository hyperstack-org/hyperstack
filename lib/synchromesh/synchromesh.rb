require 'synchromesh/configuration'
# Provides the configuration and the two basic routines for the server
# to indicate that records have changed: after_change and after_destroy
module Synchromesh
  extend Configuration

  def self.config_reset
    @pusher = nil
  end

  define_setting :transport, :none
  define_setting :opts, {}
  define_setting :channel_prefix
  define_setting :client_logging, true

  def self.app_id
    opts[:app_id] || Pusher.app_id if transport == :pusher
  end

  def self.key
    opts[:key] || Pusher.key if transport == :pusher
  end

  def self.secret
    opts[:secret] || Pusher.secret if transport == :pusher
  end

  def self.encrypted
    opts.key?(:encrypted) ? opts[:encrypted] : true
  end

  def self.seconds_polled_data_will_be_retained
    opts[:seconds_polled_data_will_be_retained] || (5 * 60)
  end

  def self.seconds_between_poll
    opts[:seconds_between_poll] || 0.5
  end

  def self.pusher
    unless @pusher
      unless channel_prefix
        self.transport = nil
        raise '******** NO CHANNEL PREFIX SET ***************'
      end
      @pusher = Pusher::Client.new(
        opts || { app_id: app_id, key: key, secret: secret }
      )
    end
    @pusher
  end

  def self.channel
    channel_prefix.to_s
  end

  def self.after_change(model)
    InternalPolicy.regulate_broadcast(model) do |data|
      send_to_transport('change', data)
    end
  end

  def self.after_destroy(model)
    InternalPolicy.regulate_broadcast(model) do |data|
      send_to_transport('destroy', data)
    end
  end

  def self.send_to_transport(message, data)
    case transport
    when :pusher
      pusher.trigger("#{Synchromesh.channel}-#{data[:channel]}", message, data)
    when :simple_poller
      SimplePoller.write(data[:channel], message, data)
    else
      transport_error
    end
  end

  def self.transport_error
    unless transport == :none
      raise "Unknown transport #{Synchromesh.transport} - not supported"
    end
  end
end
