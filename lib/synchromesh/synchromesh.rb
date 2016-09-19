require 'synchromesh/configuration'
# Provides the configuration and the two basic routines for the server
# to indicate that records have changed: after_change and after_destroy
module Synchromesh

  extend Configuration

  def self.config_reset
    Object.send(:remove_const, :Application) if @fake_application_defined
    policy = begin
      Object.const_get 'ApplicationPolicy'
    rescue Exception => e
      raise e unless e.is_a?(NameError) && e.message == "uninitialized constant ApplicationPolicy"
    end
    application = begin
      Object.const_get('Application')
    rescue Exception => e
      raise e unless e.is_a?(NameError) && e.message == "uninitialized constant Application"
    end if policy
    if policy && !application
      Object.const_set 'Application', Class.new
      @fake_application_defined = true
    end
    @pusher = nil
  end

  define_setting(:transport, :none) do |transport|
    if transport == :action_cable
      require 'synchromesh/action_cable'
      Rails.application.config.cache_store = :memory_store if Rails.application.config.cache_store = :null_store
      opts[:refresh_channels_every] = :never
    elsif opts[:refresh_channels_every] == :never
      opts[:refresh_channels_every] = nil
    end
  end

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
    opts[:refresh_channels_timeout] || 5.seconds
  end

  def self.refresh_channels_every
    opts[:refresh_channels_every] || 2.minutes
  end

  def self.refresh_channels
    new_channels = pusher.channels[:channels].collect do |channel|
      channel.gsub(/^#{Regexp.quote(Synchromesh.channel)}/,'')
    end
  end

  def self.send(channel, data)
    if transport == :pusher
      pusher.trigger("#{Synchromesh.channel}-#{data[1][:channel]}", *data)
    elsif transport == :action_cable
      ActionCable.server.broadcast("synchromesh-#{channel}", message: data[0], data: data[1])
    end
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

  def self.authorization(salt, channel, session_id)
    secret_key = Rails.application.secrets[:secret_key_base]
    Digest::SHA1.hexdigest(
      "salt: #{salt}, channel: #{channel}, session_id: #{session_id}, secret_key: #{secret_key}"
    )
  end

  def self.after_change(model)
    Thread.new do
      InternalPolicy.regulate_broadcast(model) do |data|
        Connection.send(data[:channel], ['change', data])
      end
    end
  end

  def self.after_destroy(model)
    Thread.new do
      InternalPolicy.regulate_broadcast(model) do |data|
        Connection.send(data[:channel], ['destroy', data])
      end
    end
  end

  Connection.transport = self

end
