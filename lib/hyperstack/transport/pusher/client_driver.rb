module Hyperstack
  module Transport
    module Pusher
      class ClientDriver
        def self.init
          if Hyperstack.pusher_options[:client_logging] && `console && console.log`
            `Pusher.log = function(message) {console.log(message);}`
          end

          pusher_api = nil

          %x{
            var pusher_config = {
              encrypted: #{Hyperstack.pusher_options[:encrypted]},
              cluster: #{Hyperstack.pusher_options[:cluster]}

            };
            pusher_api = new Pusher(#{Hyperstack.pusher_options[:key]}, pusher_config)
          }
          Hyperstack.pusher_options[:pusher_api] = pusher_api

          if Hyperstack.options.has_key?(:session_id)
            notification_channel = "#{Hyperstack.transport_notification_channel_prefix}#{Hyperstack.session_id}"
            Hyperstack.pusher_options[:channel] = pusher_api.JS.subscribe(notification_channel)
            Hyperstack.pusher_options[:channel].JS.bind('update', `function(data){
              return Opal.Hyperstack.$const_get('Transport').$const_get('NotificationProcessor').$process_notification(Opal.Hash.$new(data));
            }`)
          end

          @pusher_instance = pusher_api
        end

        def self.pusher_instance
          @pusher_instance
        end
      end
    end
  end
end