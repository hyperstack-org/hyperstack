#### this is going to need some refactoring so that HyperMesh can add its methods in here...

module Hyperloop
  # Client side handling of synchronization messages
  # When a synchronization message comes in, the client will sync_dispatch
  # We use ERB to determine the configuration and implement the appropriate
  # client interface to sync_change or sync_destroy

  class Application
    def self.acting_user_id
      ClientDrivers.opts[:acting_user_id]
    end
  end


  if RUBY_ENGINE == 'opal'
    def self.connect(*channels)
      channels.each do |channel|
        if channel.is_a? Class
          IncomingBroadcast.connect_to(channel.name)
        elsif channel.is_a?(String) || channel.is_a?(Array)
          IncomingBroadcast.connect_to(*channel)
        elsif channel.id
          IncomingBroadcast.connect_to(channel.class.name, channel.id)
        else
          raise "cannot connect to model before it has been saved"
        end
      end
    end

    def self.connect_session
      connect(['Hyperloop::Session', ClientDrivers.opts[:id].split('-').last])
    end

    def self.action_cable_consumer
      ClientDrivers.opts[:action_cable_consumer]
    end

    class IncomingBroadcast

      def self.open_channels
        @open_channels ||= Set.new
      end

      def self.add_connection(channel_name, id = nil)
        channel_string = "#{channel_name}#{'-'+id.to_s if id}"
        open_channels << channel_string
        channel_string
      end

      def self.connect_to(channel_name, id = nil)
        channel_string = add_connection(channel_name, id)
        if ClientDrivers.opts[:transport] == :pusher
          channel = "#{ClientDrivers.opts[:channel]}-#{channel_string}"
          %x{
            var channel = #{ClientDrivers.opts[:pusher_api]}.subscribe(#{channel.gsub('::', '==')});
            channel.bind('dispatch', #{ClientDrivers.opts[:dispatch]})
            channel.bind('pusher:subscription_succeeded', #{lambda {ClientDrivers.get_queued_data("connect-to-transport", channel_string)}})
          }
        elsif ClientDrivers.opts[:transport] == :action_cable
          channel = "#{ClientDrivers.opts[:channel]}-#{channel_string}"
          HTTP.post(ClientDrivers.polling_path('action-cable-auth', channel)).then do |response|
            %x{
              #{Hyperloop.action_cable_consumer}.subscriptions.create(
                {
                  channel: "Hyperloop::ActionCableChannel",
                  client_id: #{ClientDrivers.opts[:id]},
                  hyperloop_channel: #{channel_string},
                  authorization: #{response.json[:authorization]},
                  salt: #{response.json[:salt]}
                },
                {
                  connected: function() {
                    #{ClientDrivers.get_queued_data("connect-to-transport", channel_string)}
                  },
                  received: function(data) {
                    #{ClientDrivers.sync_dispatch(JSON.parse(`JSON.stringify(data)`)['data'])}
                  }
                }
              )
            }
          end
        else
          HTTP.get(ClientDrivers.polling_path(:subscribe, channel_string))
        end
      end
    end
  end

  class ClientDrivers
    include React::IsomorphicHelpers

    def self.sync_dispatch(data)
      # TODO old synchromesh double checked at this point to make sure that this client
      # expected to recieve from the channel the data was sent on.  Was that really needed?
      data[:operation].constantize.dispatch_from_server(data[:params])
    end

    # save the configuration info needed in window.HyperloopOpts

    # we keep a list of all channels by session with connections in progress
    # for each broadcast we check the list, and add the message to a queue for that
    # session.  When the client is informed that the connection has completed
    # we call the server,  this will return ALL the broadcasts (cool) and
    # will remove the session from the list.

    prerender_footer do |controller|
      next if Hyperloop.transport == :none
      if defined?(PusherFake)
        path = ::Rails.application.routes.routes.detect do |route|
          route.app == Hyperloop::Engine ||
            (route.app.respond_to?(:app) && route.app.app == Hyperloop::Engine)
        end.path.spec
        pusher_fake_js = PusherFake.javascript(
          auth: { headers: { 'X-CSRF-Token' => controller.send(:form_authenticity_token) } },
          authEndpoint: "#{path}/hyperloop-pusher-auth"
        )
      end
      controller.session.delete 'hyperloop-dummy-init' unless controller.session.id
      id = "#{SecureRandom.uuid}-#{controller.session.id}"
      auto_connections = Hyperloop::AutoConnect.channels(id, controller.acting_user)
      config_hash = {
        transport: Hyperloop.transport,
        id: id,
        acting_user_id: (controller.acting_user && controller.acting_user.id),
        client_logging: Hyperloop.client_logging,
        pusher_fake_js: pusher_fake_js,
        key: Hyperloop.key,
        cluster: Hyperloop.cluster,
        encrypted: Hyperloop.encrypted,
        channel: Hyperloop.channel,
        form_authenticity_token: controller.send(:form_authenticity_token),
        seconds_between_poll: Hyperloop.seconds_between_poll,
        auto_connect:  auto_connections
      }
      path = ::Rails.application.routes.routes.detect do |route|
        # not sure why the second check is needed.  It happens in the test app
        route.app == Hyperloop::Engine or (route.app.respond_to?(:app) and route.app.app == Hyperloop::Engine)
      end
      raise 'Hyperloop::Engine mount point not found.  Check your config/routes.rb file' unless path
      path = path.path.spec
      "<script type='text/javascript'>\n"\
        "window.HyperloopEnginePath = '#{path}';\n"\
        "window.HyperloopOpts = #{config_hash.to_json}\n"\
      "</script>\n"
    end if RUBY_ENGINE != 'opal'

    class << self
      attr_reader :opts
    end

    def self.get_queued_data(operation, channel = nil, opts = {})
      HTTP.get(polling_path(operation, channel), opts).then do |response|
        response.json.each do |data|
          sync_dispatch(data[1])
        end
      end
    end

    def self.initialize_client_drivers_on_boot

      if @initialized
        # 1) skip initialization if already initialized
        # 2) if running action_cable make sure connection is up after pinging the server_up
        #    action cable closes the connection if files change on the server
        HTTP.get("#{`window.HyperloopEnginePath`}/server_up") do
          `#{Hyperloop.action_cable_consumer}.connection.open()` if `#{Hyperloop.action_cable_consumer}.connection.disconnected`
        end if Hyperloop.action_cable_consumer
        return
      end

      @initialized = true
      @opts = {}

      if on_opal_client?
        if RUBY_ENGINE == 'opal'
          @opts = Hash.new(`window.HyperloopOpts`)
        end

        if opts[:transport] == :pusher

          opts[:dispatch] = lambda do |data|
            sync_dispatch JSON.parse(`JSON.stringify(#{data})`)
          end

          if opts[:client_logging] && `window.console && window.console.log`
            `Pusher.log = function(message) {window.console.log(message);}`
          end
          if opts[:pusher_fake_js]
            opts[:pusher_api] = `eval(#{opts[:pusher_fake_js]})`
          else
            h = nil
            pusher_api = nil
            %x{
              h = {
                encrypted: #{opts[:encrypted]},
                cluster: #{opts[:cluster]},
                authEndpoint: window.HyperloopEnginePath+'/hyperloop-pusher-auth',
                auth: {headers: {'X-CSRF-Token': #{opts[:form_authenticity_token]}}}
              };
              pusher_api = new Pusher(#{opts[:key]}, h)
            }
            opts[:pusher_api] = pusher_api
          end
          Hyperloop.connect(*opts[:auto_connect])
        elsif opts[:transport] == :action_cable
          opts[:action_cable_consumer] =
            `ActionCable.createConsumer.apply(ActionCable, #{[*opts[:action_cable_consumer_url]]})`
          Hyperloop.connect(*opts[:auto_connect])
        elsif opts[:transport] == :simple_poller
          opts[:auto_connect].each { |channel| IncomingBroadcast.add_connection(*channel) }
          every(opts[:seconds_between_poll]) do
            get_queued_data(:read, nil, headers: {'X-HYPERLOOP-SILENT-REQUEST' =>  true })
          end
        end
      end
    end

    def self.polling_path(to, id = nil)
      s = "#{`window.HyperloopEnginePath`}/hyperloop-#{to}/#{opts[:id]}"
      s = "#{s}/#{id}" if id
      s
    end
  end
end
