module Hyperloop
  module Resource
    class ClientDrivers
      class << self
        attr_reader :opts
      end

      # @private
      def self.initialize_client_drivers_on_boot

        return if @initialized

        @initialized = true
        @opts = {}

        @opts = Hash.new(`window.HyperloopOpts`)
        @opts[:hyper_record_update_channel] = "hyper-record-update-channel-#{@opts[:session_id]}"
        case @opts[:resource_transport]
        when :pusher
          if @opts[:pusher][:client_logging] && `console && console.log`
            `Pusher.log = function(message) {console.log(message);}`
          end

          h = nil
          pusher_api = nil
          %x{
            h = {
              encrypted: #{@opts[:pusher][:encrypted]},
              cluster: #{@opts[:pusher][:cluster]}

            };
            pusher_api = new Pusher(#{@opts[:pusher][:key]}, h)
          }
          @opts[:pusher][:pusher_api] = pusher_api
          @opts[:pusher][:channel] = pusher_api.JS.subscribe(@opts[:hyper_record_update_channel])
          @opts[:pusher][:channel].JS.bind('update', `function(data){
            return Opal.Hyperloop.$const_Get('Resource').$const_get('NotificationProcessor').$process(Opal.Hash.$new(data));
          }`)

        when :action_cable
          opts[:action_cable_consumer] =
            `ActionCable.createConsumer.apply(ActionCable, #{[*opts[:action_cable_consumer_url]]})`
          %x{
            #{opts[:action_cable_consumer]}.subscriptions.create({ channel: 'ResourceChannel', channel_id: #{@opts[:hyper_record_update_channel]} }, {
                received: function(data) {
                  return Opal.Hyperloop.$const_Get('Resource').$const_get('NotificationProcessor').$process(Opal.Hash.$new(data));
                }
              })
            }
        end
      end

    end
  end
end
