# Provides the configuration and the two basic routines for the server
# to indicate that records have changed: after_change and after_destroy
module Hyperloop

  def self.initialize_policies
    reset_operations unless @config_reset_called
  end

  on_config_reset do
    reset_operations
  end

  def self.reset_operations
    @config_reset_called = true
    Rails.configuration.tap do |config|
      # config.eager_load_paths += %W(#{config.root}/app/hyperloop/models)
      # config.autoload_paths += %W(#{config.root}/app/hyperloop/models)
      # config.assets.paths << ::Rails.root.join('app', 'hyperloop').to_s
      config.after_initialize { Connection.build_tables }
    end
    Object.send(:remove_const, :Application) if @fake_application_defined
    policy = begin
      Object.const_get 'ApplicationPolicy'
    rescue LoadError
    rescue NameError => e
      raise e unless e.message =~ /uninitialized constant ApplicationPolicy/
    end
    application = begin
      Object.const_get('Application')
    rescue LoadError
    rescue NameError => e
      raise e unless e.message =~ /uninitialized constant Application/
    end if policy
    if policy && !application
      Object.const_set 'Application', Class.new
      @fake_application_defined = true
    end
    begin
      Object.const_get 'Hyperloop::ApplicationPolicy'
    rescue LoadError
    rescue NameError => e
      raise e unless e.message =~ /uninitialized constant Hyperloop::ApplicationPolicy/
    end
    @pusher = nil
  end

  define_setting(:transport, :none) do |transport|
    if transport == :action_cable
      require 'hyper-operation/transport/action_cable'
      opts[:refresh_channels_every] = :never
      import 'action_cable', client_only: true if Rails.configuration.hyperloop.auto_config
    elsif transport == :pusher
      require 'pusher'
      import 'hyperloop/pusher', client_only: true if Rails.configuration.hyperloop.auto_config
      opts[:refresh_channels_every] = nil if opts[:refresh_channels_every] == :never
    else
      opts[:refresh_channels_every] = nil if opts[:refresh_channels_every] == :never
    end
  end

  define_setting :opts, {}
  define_setting :channel_prefix, 'synchromesh'
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

  def self.cluster
    # mt1 is the default Pusher app cluster
    opts[:cluster] || 'mt1' if transport == :pusher
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
    new_channels = pusher.channels[:channels].collect do |channel, _etc|
      channel.gsub(/^#{Regexp.quote(Hyperloop.channel)}\-/, '').gsub('==', '::')
    end
  end

  def self.send_data(channel, data)
    if !on_server?
      send_to_server(channel, data)
    elsif transport == :pusher
      pusher.trigger("#{Hyperloop.channel}-#{data[1][:channel].gsub('::', '==')}", *data)
    elsif transport == :action_cable
      ActionCable.server.broadcast("hyperloop-#{channel}", message: data[0], data: data[1])
    end
  end

  def self.on_server?
    Rails.const_defined? 'Server'
  end

  def self.pusher
    unless @pusher
      unless channel_prefix
        self.transport = nil
        raise '******** NO CHANNEL PREFIX SET ***************'
      end
      @pusher = Pusher::Client.new(
        opts || { app_id: app_id, key: key, secret: secret, cluster: cluster }
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

  def self.send_to_server(channel, data) # TODO this should work the same/similar to HyperMesh / Models way of sending to console
    salt = SecureRandom.hex
    authorization = authorization(salt, channel, data[1][:broadcast_id])
    raise 'no server running' unless Connection.root_path
    uri = URI("#{Connection.root_path}console_update")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request.body = {
      channel: channel, data: data, salt: salt, authorization: authorization
    }.to_json
    http.request(request)
  end

  def self.dispatch(data)
    if !Hyperloop.on_server? && Connection.root_path
      Hyperloop.send_to_server(data[:channel], [:dispatch, data])
    else
      Connection.send_to_channel(data[:channel], [:dispatch, data])
    end
  end

  Connection.transport = self
end
