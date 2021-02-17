#### this is going to need some refactoring so that HyperMesh can add its methods in here...

module Hyperstack
  # Client side handling of synchronization messages
  # When a synchronization message comes in, the client will sync_dispatch
  # We use ERB to determine the configuration and implement the appropriate
  # client interface to sync_change or sync_destroy

  def self.anti_csrf_token
    ClientDrivers.opts[:form_authenticity_token]
  end

  class Application
    extend Component::IsomorphicHelpers::ClassMethods

    if on_opal_client?
      def self.acting_user_id
        ClientDrivers.opts[:acting_user_id]
      end
    else
      def self.acting_user_id
        ClientDrivers.client_drivers_get_acting_user_id
      end
    end

    def self.env
      @env = ClientDrivers.env unless @env
      @env
    end

    def self.production?
      env == 'production'
    end
  end


  if RUBY_ENGINE == 'opal'
    # Patch in a dummy copy of Model.load in case we are not using models
    # this will be defined properly by hyper-model
    module Model
      def self.load
        Promise.new.tap { |promise| promise.resolve(yield) }
      end unless respond_to?(:load)
    end

    def self.connect(*channels)
      channels.each do |channel|
        if channel.is_a? Class
          IncomingBroadcast.connect_to(channel.name)
        elsif channel.is_a?(String) || channel.is_a?(Array)
          IncomingBroadcast.connect_to(*channel)
        elsif channel.respond_to?(:id)
          Hyperstack::Model.load do
            channel.id
          end.then do |id|
            raise "Hyperstack.connect cannot connect to #{channel.inspect}.  "\
                  "The id is nil. This can be caused by connecting to a model "\
                  "that is not saved, or that does not exist." unless id
            IncomingBroadcast.connect_to(channel.class.name, id)
          end
        else
          raise "Hyperstack.connect cannot connect to #{channel.inspect}.\n"\
                "Channels must be either a class, or a class name,\n"\
                "a string in the form 'ClassName-id',\n"\
                "an array in the form [class, id] or [class-name, id],\n"\
                "or an object that responds to the id method with a non-nil value"
        end
      end
    end

    def self.connect_session
      connect(['Hyperstack::Session', ClientDrivers.opts[:id].split('-').last])
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
        return if open_channels.include? channel_string
        open_channels << channel_string
        channel_string
      end

      def self.connect_to(channel_name, id = nil)
        channel_string = add_connection(channel_name, id)
        return unless channel_string # already connected!
        if ClientDrivers.opts[:transport] == :pusher
          channel = "#{ClientDrivers.opts[:channel]}-#{channel_string}"
          %x{
            var channel = #{ClientDrivers.opts[:pusher_api]}.subscribe(#{channel.gsub('::', '==')});
            channel.bind('dispatch', #{ClientDrivers.opts[:dispatch]})
            channel.bind('pusher:subscription_succeeded', #{lambda {ClientDrivers.get_queued_data("connect-to-transport", channel_string)}})
          }
          @pusher_dispatcher_registered = true
        elsif ClientDrivers.opts[:transport] == :action_cable
          channel = "#{ClientDrivers.opts[:channel]}-#{channel_string}"
          Hyperstack::HTTP.post(ClientDrivers.polling_path('action-cable-auth', channel), headers: { 'X-CSRF-Token' => ClientDrivers.opts[:form_authenticity_token] }).then do |response|
            %x{
              var fix_opal_0110 = 'return';
              #{Hyperstack.action_cable_consumer}.subscriptions.create(
                {
                  channel: "Hyperstack::ActionCableChannel",
                  client_id: #{ClientDrivers.opts[:id]},
                  hyperstack_channel: #{channel_string},
                  authorization: #{response.json[:authorization]},
                  salt: #{response.json[:salt]}
                },
                {
                  connected: function() {
                    if (#{ClientDrivers.env == 'development'}) { console.log("ActionCable connected to: ", channel_string); }
                    #{ClientDrivers.complete_connection(channel_string)}
                  },
                  received: function(data) {
                    if (#{ClientDrivers.env == 'development'}) { console.log("ActionCable received: ", data); }
                    #{st = Time.now; puts "receiving at #{Time.now}"}
                    #{ClientDrivers.sync_dispatch(JSON.parse(`JSON.stringify(data)`)['data'])}
                    #{puts "synced dispatch at #{Time.now} total time = #{Time.now - st}"
                    }
                  }
                }
              )
            }
          end
        else
          Hyperstack::HTTP.get(ClientDrivers.polling_path(:subscribe, channel_string))
        end
      end
    end
  end

  class ClientDrivers
    include Hyperstack::Component::IsomorphicHelpers

    def self.sync_dispatch(data)
      # TODO old synchromesh double checked at this point to make sure that this client
      # expected to recieve from the channel the data was sent on.  Was that really needed?
      data[:operation].constantize.dispatch_from_server(data[:params])
    end

    # save the configuration info needed in window.HyperstackOpts

    # we keep a list of all channels by session with connections in progress
    # for each broadcast we check the list, and add the message to a queue for that
    # session.  When the client is informed that the connection has completed
    # we call the server,  this will return ALL the broadcasts (cool) and
    # will remove the session from the list.

    prerender_footer do |controller|
      unless Hyperstack.transport == :none
        if defined?(PusherFake)
          path = ::Rails.application.routes.routes.detect do |route|
            route.app == Hyperstack::Engine ||
              (route.app.respond_to?(:app) && route.app.app == Hyperstack::Engine)
          end.path.spec
          pusher_fake_js = PusherFake.javascript(
            auth: { headers: { 'X-CSRF-Token' => controller.send(:form_authenticity_token) } },
            authEndpoint: "#{path}/hyperstack-pusher-auth"
          )
        end
        controller.session.delete 'hyperstack-dummy-init' unless controller.session.id
        id = "#{SecureRandom.uuid}-#{controller.session.id}"
        auto_connections = Hyperstack::AutoConnect.channels(id, controller.acting_user) rescue []
      end
      config_hash = {
        transport: Hyperstack.transport,
        id: id,
        acting_user_id: (controller.acting_user.respond_to?(:id) && controller.acting_user.id),
        env: ::Rails.env,
        client_logging: Hyperstack.client_logging,
        pusher_fake_js: pusher_fake_js,
        key: Hyperstack.key,
        cluster: Hyperstack.cluster,
        encrypted: Hyperstack.encrypted,
        channel: Hyperstack.channel,
        form_authenticity_token: controller.send(:form_authenticity_token),
        seconds_between_poll: Hyperstack.seconds_between_poll,
        auto_connect:  auto_connections
      }
      path = ::Rails.application.routes.routes.detect do |route|
        # not sure why the second check is needed.  It happens in the test app
        route.app == Hyperstack::Engine or (route.app.respond_to?(:app) and route.app.app == Hyperstack::Engine)
      end
      if path
        path = path.path.spec
        "<script type='text/javascript'>\n"\
          "window.HyperstackEnginePath = '#{path}';\n"\
          "window.HyperstackOpts = #{config_hash.to_json}\n"\
        "</script>\n"
      else
        "<script type='text/javascript'>\n"\
          "window.HyperstackOpts = #{config_hash.to_json}\n"\
        "</script>\n"
      end
    end if RUBY_ENGINE != 'opal'

    class << self
      attr_reader :opts
    end

    isomorphic_method(:client_drivers_get_acting_user_id) do |f|
      f.send_to_server if RUBY_ENGINE == 'opal'
      f.when_on_server { (controller.acting_user && controller.acting_user.id) }
    end

    isomorphic_method(:env) do |f|
      f.when_on_client { opts[:env] }
      f.send_to_server
      f.when_on_server { ::Rails.env }
    end

    def self.complete_connection(channel, retries = 10)
      get_queued_data('connect-to-transport', channel).fail do
        after(0.25) { complete_connection(channel, retries - 1) } unless retries.zero?
      end
    end

    def self.get_queued_data(operation, channel = nil, opts = {})
      Hyperstack::HTTP.get(polling_path(operation, channel), opts).then do |response|
        response.json.each do |data|
          `console.log("simple_poller received: ", data)` if ClientDrivers.env == 'development'
          sync_dispatch(data[1])
        end
      end
    end

    def self.initialize_client_drivers_on_boot

      if @initialized
        # 1) skip initialization if already initialized
        if on_opal_client? && Hyperstack.action_cable_consumer
          # 2) if running action_cable make sure connection is up after pinging the server_up
          #    action cable closes the connection if files change on the server
          Hyperstack::HTTP.get("#{`window.HyperstackEnginePath`}/server_up") do
            `#{Hyperstack.action_cable_consumer}.connection.open()` if `#{Hyperstack.action_cable_consumer}.connection.disconnected`
          end
        end
        return
      end

      @initialized = true
      @opts = {}

      if on_opal_client?

        @opts = Hash.new(`window.HyperstackOpts`)

        if opts[:transport] != :none && `typeof(window.HyperstackEnginePath) == 'undefined'`
          raise "No hyperstack mount point found!\nCheck your Rails routes.rb file";
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
                authEndpoint: window.HyperstackEnginePath+'/hyperstack-pusher-auth',
                auth: {headers: {'X-CSRF-Token': #{opts[:form_authenticity_token]}}}
              };
              pusher_api = new Pusher(#{opts[:key]}, h)
            }
            opts[:pusher_api] = pusher_api
          end
          Hyperstack.connect(*opts[:auto_connect])
        elsif opts[:transport] == :action_cable
          opts[:action_cable_consumer] =
            `ActionCable.createConsumer.apply(ActionCable, #{[*opts[:action_cable_consumer_url]]})`
          Hyperstack.connect(*opts[:auto_connect])
        elsif opts[:transport] == :simple_poller
          opts[:auto_connect].each { |channel| IncomingBroadcast.add_connection(*channel) }
          every(opts[:seconds_between_poll]) do
            get_queued_data(:read, nil)
          end
        end
      end
    end

    def self.polling_path(to, id = nil)
      s = "#{`window.HyperstackEnginePath`}/hyperstack-#{to}/#{opts[:id]}"
      s = "#{s}/#{id}" if id
      s
    end
  end
end
