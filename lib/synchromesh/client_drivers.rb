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
          IncomingBroadcast.connect_to(channel.name, nil)
        elsif channel.is_a? String
          IncomingBroadcast.connect_to(channel, nil)
        elsif channel.is_a? Array
          IncomingBroadcast.connect_to(*channel)
        elsif channel.id
          IncomingBroadcast.connect_to(channel.class.name, channel.id)
        else
          raise "cannot connect to model before it has been saved"
        end
      end
    end

    class IncomingBroadcast
      def self.receive(data, &block)
        in_transit[data[:broadcast]].receive(data, &block)
      end

      def klass
        Object.const_get(@klass)
      end

      attr_reader :record
      attr_reader :previous_changes

      def self.open_channels
        @open_channels ||= Set.new
      end

      def self.connect_to(channel_name, id)
        channel_string = "#{channel_name}#{'-'+id.to_s if id}"
        open_channels << channel_string
        if ClientDrivers.opts[:transport] == :pusher
          channel = "#{ClientDrivers.opts[:channel]}-#{channel_string}"
          %x{
            var channel = #{ClientDrivers.opts[:pusher_api]}.subscribe(#{channel});
            channel.bind('change', #{ClientDrivers.opts[:change]});
            channel.bind('destroy', #{ClientDrivers.opts[:destroy]});
          }
        else
          HTTP.get(ClientDrivers.polling_path(:subscribe, channel_string))
        end
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

      def receive(data, &block)
        @channels ||= self.class.open_channels.intersection data[:channels]
        raise "synchromesh security violation" unless @channels.include? data[:channel]
        @received << data[:channel]
        @klass ||= data[:klass]
        @record.merge! data[:record]
        @previous_changes.merge! data[:previous_changes]
        yield complete! if @channels == @received
      end

      def complete!
        self.class.in_transit.delete @id
      end
    end

  end
  class ClientDrivers
    include React::IsomorphicHelpers

    # sync_changes: Wait till we are done with any concurrent model saves, then
    # hydrate the data (which will update any attributes) and sync the scopes.

    def self.sync_change(data)
      IncomingBroadcast.receive(data) do |broadcast|
        ReactiveRecord::Base.when_not_saving(broadcast.klass) do |klass|
          record = klass._react_param_conversion(broadcast.record)
          record.backing_record.previous_changes = broadcast.previous_changes
          puts "sync_change receives record #{record}"
          record.backing_record.sync_scopes2
          puts "scopes have been synced"
        end
      end
    end

    # sync_destroy: Hydrate the data, then destroy the record, cleanup
    # and syncronize the scopes.

    def self.sync_destroy(data)
      IncomingBroadcast.receive(data) do |broadcast|
        record = broadcast.klass._react_param_conversion(broadcast.record)
        ReactiveRecord::Base.load_data { record.destroy }
        record.backing_record.destroyed = true
        record.backing_record.sync_scopes2
      end
    end

    # save the configuration info needed in window.SynchromeshOpts

    prerender_footer do |controller|
      if defined?(PusherFake)
        path = ::Rails.application.routes.routes.detect do |route|
          route.app == ReactiveRecord::Engine ||
            (route.app.respond_to?(:app) && route.app.app == ReactiveRecord::Engine)
        end.path.spec
        pusher_fake_js = PusherFake.javascript(
          auth: {headers: {'X-CSRF-Token' => controller.send(:form_authenticity_token)}},
          authEndpoint: "#{path}/synchromesh-pusher-auth"
        )
      end
      config_hash = {
        transport: Synchromesh.transport,
        client_logging: Synchromesh.client_logging,
        pusher_fake_js: pusher_fake_js,
        key: Synchromesh.key,
        encrypted: Synchromesh.encrypted,
        channel: Synchromesh.channel,
        form_authenticity_token: controller.send(:form_authenticity_token),
        seconds_between_poll: Synchromesh.seconds_between_poll,
        auto_connect: Synchromesh::AutoConnect.channels(controller.acting_user)
      }
      "<script type='text/javascript'>\n"\
      "window.SynchromeshOpts = #{config_hash.to_json}\n"\
      "</script>\n"
    end if RUBY_ENGINE != 'opal'

    def self.opts
      @opts ||= Hash.new(`window.SynchromeshOpts`)
    end

    # Before first mount, hook up callbacks depending on what kind of transport
    # we are using.

    before_first_mount do
      if on_opal_client?
        if opts[:transport] == :pusher

          opts[:change] = lambda do |data|
            sync_change Hash.new(data)
          end

          opts[:destroy] = lambda do |data|
            sync_destroy Hash.new(data)
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
        elsif opts[:transport] == :simple_poller

          every(opts[:seconds_between_poll]) do
            HTTP.get(polling_path(:read)).then do |response|
              response.json.each do |update|
                send "sync_#{update[0]}", update[1]
              end
            end
          end
        end
        Synchromesh.connect(*opts[:auto_connect])
      end
    end

    def self.polling_path(to, id = nil)
      "#{`window.ReactiveRecordEnginePath`}/synchromesh-#{to}/#{id}"
    end
  end
end
