require 'synchromesh/configuration'
# Provides the configuration and the two basic routines for the server
# to indicate that records have changed: after_change and after_destroy
module Synchromesh

  #.refresh_timeout
  #.refresh (method)
  #.refresh_in

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

  def self.expire_polled_connection_in
    opts[:expire_polled_connection_in] || (5 * 60)
  end

  def self.seconds_between_poll
    opts[:seconds_between_poll] || 0.5
  end

  def self.expire_new_connection_in
    opts[:expire_new_connection_in] || 10.seconds
  end

  def self.refresh_channels_timeout
    opts[:refresh_timeout] || 5.seconds
  end

  def self.refresh_channels_every
    opts[:refresh_every] || 2.minutes
  end

  def self.refresh_channels
    new_channels = pusher.channels[:channels].collect do |channel|
      channel.gsub(/^#{Regexp.quote(Synchromesh.channel)}/,'')
    end
  end

  def self.send(channel, data)
    pusher.trigger("#{Synchromesh.channel}-#{data[1][:channel]}", *data)
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
    "private-#{channel_prefix}"
  end

  def self.after_change(model)
    InternalPolicy.regulate_broadcast(model) do |data|
      Connection.send(data[:channel], ['change', data])
    end
  end

  def self.after_destroy(model)
    InternalPolicy.regulate_broadcast(model) do |data|
      Connection.send(data[:channel], ['destroy', data])
    end
  end

  Connection.transport = self

end
