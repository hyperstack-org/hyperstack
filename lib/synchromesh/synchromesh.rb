require 'synchromesh/configuration'
# Provides the configuration and the two basic routines for the server
# to indicate that records have changed: after_change and after_destroy
module HyperMesh

  extend Configuration

  def self.load(*args, &block)
    ReactiveRecord.load(*args, &block)
  end

  def self.initialize_policies
    config_reset unless @config_reset_called
  end

  def self.config_reset
    @config_reset_called = true
    Object.send(:remove_const, :Application) if @fake_application_defined
    policy = begin
      Object.const_get 'ApplicationPolicy'
    rescue Exception => e
      #raise e unless e.is_a?(NameError) && e.message == "uninitialized constant ApplicationPolicy"
    rescue LoadError
    end
    application = begin
      Object.const_get('Application')
    rescue LoadError
    rescue Exception => e
      #raise e unless e.is_a?(NameError) && e.message == "uninitialized constant Application"
    end if policy
    if policy && !application
      Object.const_set 'Application', Class.new
      @fake_application_defined = true
    end
    @pusher = nil
    Connection.build_tables
  end

  define_setting(:transport, :none) do |transport|
    if transport == :action_cable
      require 'synchromesh/action_cable'
      opts[:refresh_channels_every] = :never
    else
      require 'pusher' if transport == :pusher
      opts[:refresh_channels_every] = nil if opts[:refresh_channels_every] == :never
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
      channel.gsub(/^#{Regexp.quote(HyperMesh.channel)}/,'')
    end
  end

  def self.send(channel, data)
    if on_console?
      send_to_server(channel, data)
    elsif transport == :pusher
      pusher.trigger("#{HyperMesh.channel}-#{data[1][:channel]}", *data)
    elsif transport == :action_cable
      ActionCable.server.broadcast("synchromesh-#{channel}", message: data[0], data: data[1])
    end
  end

  def self.on_console?
    defined?(Rails::Console)
  end

  def self.send_to_server(channel, data)
    salt = SecureRandom.hex
    authorization = HyperMesh.authorization(salt, channel, data[1][:broadcast_id])
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

  def self.after_commit(operation, model)
    InternalPolicy.regulate_broadcast(model) do |data|
      if HyperMesh.on_console? && Connection.root_path
        HyperMesh.send_to_server(data[:channel], [operation, data])
      else
        Connection.send_to_channel(data[:channel], [operation, data])
      end
    end
  rescue Exception
    nil  # this is because during db migration we have problems... should investigate more...
  end

  Connection.transport = self
end
