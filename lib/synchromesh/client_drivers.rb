module Synchromesh
  # Client side handling of synchronization messages
  # When a synchronization message comes in, the client will call
  # either the sync_change or sync_destroy methods.
  # Everything is setup during reactrb before_first_mount callback
  # We use ERB to determine the configuration and implement the appropriate
  # client interface to sync_change or sync_destroy

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

    def self.action_cable_consumer
      ClientDrivers.opts[:action_cable_consumer]
    end

    class IncomingBroadcast
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
            var channel = #{ClientDrivers.opts[:pusher_api]}.subscribe(#{channel});
            channel.bind('create', #{ClientDrivers.opts[:create]});
            channel.bind('change', #{ClientDrivers.opts[:change]});
            channel.bind('destroy', #{ClientDrivers.opts[:destroy]});
            channel.bind('pusher:subscription_succeeded', #{lambda {ClientDrivers.get_queued_data("connect-to-transport", channel_string)}})
          }
        elsif ClientDrivers.opts[:transport] == :action_cable
          channel = "#{ClientDrivers.opts[:channel]}-#{channel_string}"
          HTTP.post(ClientDrivers.polling_path('action-cable-auth', channel)).then do |response|
            %x{
              #{Synchromesh.action_cable_consumer}.subscriptions.create(
                {
                  channel: "Synchromesh::ActionCableChannel",
                  client_id: #{ClientDrivers.opts[:id]},
                  synchromesh_channel: #{channel_string},
                  authorization: #{response.json[:authorization]},
                  salt: #{response.json[:salt]}
                },
                {
                  connected: function() {
                    #{ClientDrivers.get_queued_data("connect-to-transport", channel_string)}
                  },
                  received: function(data) {
                    var data = #{JSON.parse(`JSON.stringify(data)`)}
                    #{ClientDrivers.send("sync_#{`data`['message']}", `data`['data'])}
                    return true
                  }
                }
              )
            }
          end
        else
          HTTP.get(ClientDrivers.polling_path(:subscribe, channel_string))
        end
      end

      def self.receive(data, operation, &block)
        in_transit[data[:broadcast_id]].receive(data, operation, &block)
      end

      def record_with_current_values
        ReactiveRecord::Base.load_data do
          backing_record = @backing_record || klass.find(record[:id]).backing_record
          if destroyed?
            backing_record.ar_instance
          else
            merge_current_values(backing_record)
          end
        end
      end

      def record_with_new_values
        klass._react_param_conversion(record).tap do |ar_instance|
          if destroyed?
            ar_instance.backing_record.destroy_associations
            ar_instance.backing_record.destroyed = true
          elsif new?
            ar_instance.backing_record.initialize_collections
          end
        end
      end

      def new?
        @is_new
      end

      def destroyed?
        @destroyed
      end

      def klass
        Object.const_get(@klass)
      end

      def to_s
        "klass: #{klass} record: #{record} new?: #{new?} destroyed?: #{destroyed?}"
      end

      # private

      attr_reader :record

      def self.open_channels
        @open_channels ||= Set.new
      end

      def self.in_transit
        @in_transit ||= Hash.new { |h, k| h[k] = new(k) }
      end

      def initialize(id)
        @id = id
        @received = Set.new
        @record = {}
        @previous_changes = {}
      end

      def receive(data, operation)
        @destroyed = operation == :destroy
        @is_new = operation == :create
        @channels ||= self.class.open_channels.intersection data[:channels]
        raise 'synchromesh security violation' unless @channels.include? data[:channel]
        @received << data[:channel]
        @klass ||= data[:klass]
        @record.merge! data[:record]
        @previous_changes.merge! data[:previous_changes]
        @backing_record = ReactiveRecord::Base.exists?(klass, record[:id])
        yield complete! if @channels == @received
      end

      def complete!
        self.class.in_transit.delete @id
      end

      def merge_current_values(br)
        current_values = Hash[*@previous_changes.collect do |attr, values|
          value = attr == :id ? record[:id] : values.first
          if br.attributes.key?(attr) &&
             br.attributes[attr].to_s != value.to_s &&
             br.attributes[attr].to_s != values.last.to_s
            puts "warning the #{attr} has changed locally - will force a reload.\n"\
                 "local value: #{br.attributes[attr]} remote value: #{value}->#{values.last}"
            return nil
          end
          [attr, value]
        end.compact.flatten].merge(br.attributes)
        klass._react_param_conversion(current_values)
      end
    end
  end

  class ClientDrivers
    include React::IsomorphicHelpers

    # sync_changes: Wait till we are done with any concurrent model saves, then
    # hydrate the data (which will update any attributes) and sync the scopes.

    def self.sync_create(data)
      IncomingBroadcast.receive(data, :create) do |broadcast|
        ReactiveRecord::Base.when_not_saving(broadcast.klass) do
          ReactiveRecord::Collection.sync_scopes broadcast
        end
      end
    end

    def self.sync_change(data)
      IncomingBroadcast.receive(data, :change) do |broadcast|
        ReactiveRecord::Base.when_not_saving(broadcast.klass) do
          ReactiveRecord::Collection.sync_scopes broadcast
        end
      end
    end

    # sync_destroy: Hydrate the data, then destroy the record, cleanup
    # and syncronize the scopes.

    def self.sync_destroy(data)
      IncomingBroadcast.receive(data, :destroy) do |broadcast|
        ReactiveRecord::Collection.sync_scopes broadcast
      end
    end

    # save the configuration info needed in window.SynchromeshOpts

    # we keep a list of all channels by session with connections in progress
    # for each broadcast we check the list, and add the message to a queue for that
    # session.  When the client is informed that the connection has completed
    # we call the server,  this will return ALL the broadcasts (cool) and
    # will remove the session from the list.

    prerender_footer do |controller|
      if defined?(PusherFake)
        path = ::Rails.application.routes.routes.detect do |route|
          route.app == ReactiveRecord::Engine ||
            (route.app.respond_to?(:app) && route.app.app == ReactiveRecord::Engine)
        end.path.spec
        pusher_fake_js = PusherFake.javascript(
          auth: { headers: { 'X-CSRF-Token' => controller.send(:form_authenticity_token) } },
          authEndpoint: "#{path}/synchromesh-pusher-auth"
        )
      end
      controller.session.delete 'synchromesh-dummy-init' unless controller.session.id
      id = "#{SecureRandom.uuid}-#{controller.session.id}"
      config_hash = {
        transport: Synchromesh.transport,
        id: id,
        client_logging: Synchromesh.client_logging,
        pusher_fake_js: pusher_fake_js,
        key: Synchromesh.key,
        encrypted: Synchromesh.encrypted,
        channel: Synchromesh.channel,
        form_authenticity_token: controller.send(:form_authenticity_token),
        seconds_between_poll: Synchromesh.seconds_between_poll,
        auto_connect: Synchromesh::AutoConnect.channels(id, controller.acting_user)
      }
      "<script type='text/javascript'>\n"\
      "window.SynchromeshOpts = #{config_hash.to_json}\n"\
      "</script>\n"
    end if RUBY_ENGINE != 'opal'

    def self.opts
      @opts ||= Hash.new(`window.SynchromeshOpts`)
    end

    def self.get_queued_data(operation, channel = nil, opts = {})
      HTTP.get(polling_path(operation, channel), opts).then do |response|
        response.json.each do |update|
          send "sync_#{update[0]}", update[1]
        end
      end
    end

    # Before first mount, hook up callbacks depending on what kind of transport
    # we are using.

    before_first_mount do
      if on_opal_client?
        if opts[:transport] == :pusher

          opts[:create] = lambda do |data|
            sync_create JSON.parse(`JSON.stringify(#{data})`)
          end

          opts[:change] = lambda do |data|
            sync_change JSON.parse(`JSON.stringify(#{data})`)
          end

          opts[:destroy] = lambda do |data|
            sync_destroy JSON.parse(`JSON.stringify(#{data})`)
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
                authEndpoint: window.ReactiveRecordEnginePath+'/synchromesh-pusher-auth',
                auth: {headers: {'X-CSRF-Token': #{opts[:form_authenticity_token]}}}
              };
              pusher_api = new Pusher(#{opts[:key]}, h)
            }
            opts[:pusher_api] = pusher_api
          end
          Synchromesh.connect(*opts[:auto_connect])
        elsif opts[:transport] == :action_cable
          opts[:action_cable_consumer] =
            `ActionCable.createConsumer.apply(ActionCable, #{[*opts[:action_cable_consumer_url]]})`
          Synchromesh.connect(*opts[:auto_connect])
        elsif opts[:transport] == :simple_poller
          opts[:auto_connect].each { |channel| IncomingBroadcast.add_connection(*channel) }
          every(opts[:seconds_between_poll]) do
            get_queued_data(:read, nil, headers: {'X-SYNCHROMESH-SILENT-REQUEST': true })
          end
        end
      end
    end

    def self.polling_path(to, id = nil)
      s = "#{`window.ReactiveRecordEnginePath`}/synchromesh-#{to}/#{opts[:id]}"
      s = "#{s}/#{id}" if id
      s
    end
  end
end
