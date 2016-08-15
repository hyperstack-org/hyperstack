module Synchromesh
  # Client side handling of synchronization messages
  # When a synchronization message comes in, the client will call
  # either the sync_change or sync_destroy methods.
  # Everything is setup during reactrb before_first_mount callback
  # We use ERB to determine the configuration and implement the appropriate
  # client interface to sync_change or sync_destroy
  class ClientDrivers
    include React::IsomorphicHelpers

    # sync_changes: Wait till we are done with any concurrent model saves, then
    # hydrate the data (which will update any attributes) and sync the scopes.

    def self.sync_change(data)
      ReactiveRecord::Base.when_not_saving(Object.const_get(data[:klass])) do |klass|
        record = klass._react_param_conversion(data[:record])
        record.backing_record.previous_changes = data[:previous_changes]
        puts "sync_change receives record #{record}"
        record.backing_record.sync_scopes2
        puts "scopes have been synced"
      end
    end

    # sync_destroy: Hydrate the data, then destroy the record, cleanup
    # and syncronize the scopes.

    def self.sync_destroy(data)
      record = Object.const_get(data[:klass])
                     ._react_param_conversion(data[:record])
      ReactiveRecord::Base.load_data { record.destroy }
      record.backing_record.destroyed = true
      record.backing_record.sync_scopes2
    end

    # Before first mount, hook up callbacks depending on what kind of transport
    # we are using.

    prerender_footer do
      config_hash = {
        transport: Synchromesh.transport,
        client_logging: Synchromesh.client_logging,
        pusher_fake: defined?(PusherFake) && PusherFake.javascript,
        key: Synchromesh.key,
        encrypted: Synchromesh.encrypted,
        channel: Synchromesh.channel,
        seconds_between_poll: Synchromesh.seconds_between_poll
      }
      "<script type='text/javascript'>\n"\
      "window.SynchromeshOpts = #{config_hash.to_json}\n"\
      "</script>\n"
    end if RUBY_ENGINE != 'opal'

    before_first_mount do
      if on_opal_client?
        opts = Hash.new(`window.SynchromeshOpts`)
        if opts[:transport] == :pusher

          change = lambda do |data|
            sync_change Hash.new(data)
          end

          destroy = lambda do |data|
            sync_destroy Hash.new(data)
          end

          if opts[:client_logging] && `window.console && window.console.log`
            `Pusher.log = function(message) {window.console.log(message);}`
          end
          if opts[:pusher_fake]
            `var pusher = eval(#{opts[:pusher_fake]});`
          else
            `var pusher = new Pusher(#{opts[:key]}, {encrypted: #{opts[:encrypted]}})`
          end
          %x{
            var channel = pusher.subscribe(#{opts[:channel]});
            channel.bind('change', #{change});
            channel.bind('destroy', #{destroy});
          }
        elsif opts[:transport] == :simple_poller

          id = nil

          HTTP.get(polling_path(:subscribe)).then do |response|
            id = response.json[:id]
          end

          every(opts[:seconds_between_poll]) do
            HTTP.get(polling_path(:read, id)).then do |response|
              response.json.each do |update|
                send "sync_#{update[0]}", update[1]
              end
            end
          end
        end
      end
    end

    def self.polling_path(to, id = nil)
      "#{`window.ReactiveRecordEnginePath`}/synchromesh-#{to}/#{id}"
    end
  end
end
