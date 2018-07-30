module Hyperloop
  module Transport
    class ClientDrivers
      # @private
      def self.initialize_client_drivers_on_boot

        return if @initialized
        @initialized = true

        opts = Hyperloop.options

        opts[:hyper_record_update_channel] = "hyper-record-update-channel-#{opts[:session_id]}"
        case opts[:notification_transport]
        when :pusher
          if opts[:pusher][:client_logging] && `console && console.log`
            `Pusher.log = function(message) {console.log(message);}`
          end

          pusher_api = nil
          %x{
            pusher_config = {
              encrypted: #{opts[:pusher][:encrypted]},
              cluster: #{opts[:pusher][:cluster]}

            };
            pusher_api = new Pusher(#{opts[:pusher][:key]}, pusher_config)
          }
          opts[:pusher][:pusher_api] = pusher_api
          opts[:pusher][:channel] = pusher_api.JS.subscribe(opts[:hyper_record_update_channel])
          opts[:pusher][:channel].JS.bind('update', `function(data){
            return Opal.Hyperloop.$const_Get('Transport').$const_get('NotificationProcessor').$process_notification(Opal.Hash.$new(data));
          }`)

        when :action_cable
          opts[:action_cable_consumer] =
            `ActionCable.createConsumer.apply(ActionCable, #{[*opts[:action_cable_consumer_url]]})`
          %x{
            #{opts[:action_cable_consumer]}.subscriptions.create({ channel: 'ResourceChannel', channel_id: #{opts[:hyper_record_update_channel]} }, {
                received: function(data) {
                  return Opal.Hyperloop.$const_Get('Transport').$const_get('NotificationProcessor').$process_notification(Opal.Hash.$new(data));
                }
              })
            }
        end
      end
    end
  end
end
