module Hyperloop
  module Resource
    class ClientDrivers
      include React::IsomorphicHelpers

      class << self
        attr_reader :opts
      end

      if RUBY_ENGINE != 'opal'

        prerender_footer do |controller|
          # next if Hyperloop.transport == :none
          # if defined?(PusherFake)
          #   path = ::Rails.application.routes.routes.detect do |route|
          #     route.app == Hyperloop::Engine ||
          #       (route.app.respond_to?(:app) && route.app.app == Hyperloop::Engine)
          #   end.path.spec
          #   pusher_fake_js = PusherFake.javascript(
          #     auth: { headers: { 'X-CSRF-Token' => controller.send(:form_authenticity_token) } },
          #     authEndpoint: "#{path}/hyperloop-pusher-auth"
          #   )
          # end

          config_hash = {
            resource_transport: Hyperloop.resource_transport,
            resource_api_base_path: Hyperloop.resource_api_base_path,
            session_id: controller.session.id,
            current_user_id: (controller.current_user.id if controller.current_user),
            form_authenticity_token: controller.send(:form_authenticity_token)
          }
          case Hyperloop.resource_transport
          when :action_cable
          when :pusher
            config_hash[:pusher] = {
              key: Hyperloop.pusher[:key],
              cluster: Hyperloop.pusher[:cluster],
              encrypted: Hyperloop.pusher[:encrypted],
              client_logging: Hyperloop.pusher[:client_logging] ? true : false
            }
          when :pusher_fake
          end

          "<script type='text/javascript'>\n"\
            "window.HyperloopOpts = #{config_hash.to_json};\n"\
            "Opal.Hyperloop.$const_get('Resource').$const_get('ClientDrivers').$initialize_client_drivers_on_boot();\n"\
          "</script>\n"
        end

      else

        # @private
        def self.initialize_client_drivers_on_boot

          return if @initialized

          @initialized = true
          @opts = {}

          if on_opal_client?

            @opts = Hash.new(`window.HyperloopOpts`)
            @opts[:hyper_record_update_channel] = "hyper-record-update-channel-#{@opts[:session_id]}"
            case @opts[:resource_transport]
            when :pusher
              if @opts[:pusher][:client_logging] && `window.console && window.console.log`
                `Pusher.log = function(message) {window.console.log(message);}`
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
                return Opal.Hyperloop.$const_get('Resource').$const_get('ClientDrivers').$process_notification(Opal.Hash.$new(data));
              }`)

            when :action_cable
              opts[:action_cable_consumer] =
                `ActionCable.createConsumer.apply(ActionCable, #{[*opts[:action_cable_consumer_url]]})`
              %x{
                #{opts[:action_cable_consumer]}.subscriptions.create({ channel: 'ResourceChannel', channel_id: #{@opts[:hyper_record_update_channel]} }, {
                    received: function(data) {
                      return Opal.Hyperloop.$const_get('Resource').$const_get('ClientDrivers').$process_notification(Opal.Hash.$new(data));
                    }
                  })
                }
            end
          end
        end

        # @private
        def self.process_notification(data)
          record_class = Object.const_get(data[:record_type])
          if data[:scope]
            scope_name, scope_params = data[:scope].split('_[')
            if scope_params
              scope_params = '[' + scope_params
              record_class._class_fetch_states[data[:scope]] = 'u'
              record_class.send("promise_#{scope_name}", *JSON.parse(scope_params)).then do |collection|
                record_class._notify_class_observers
              end.fail do |response|
                error_message = "#{record_class}.#{scope_name}(#{scope_params}), a scope failed to update!"
                `console.error(error_message)`
              end
            else
              record_class._class_fetch_states[data[:scope]] = 'u'
              record_class.send(data[:scope]).then do |collection|
                record_class._notify_class_observers
              end.fail do |response|
                error_message = "#{record_class}.#{scope_name}, a scope failed to update!"
                `console.error(error_message)`
              end
            end
          elsif data[:rest_class_method]
            record_class._class_fetch_states[data[:rest_class_method]] = 'u'
            if data[:rest_class_method].include?('_[')
              record_class._notify_class_observers
            else
              send("promise_#{data[:rest_class_method]}").then do |result|
                _notify_observers
              end.fail do |response|
                error_message = "#{self}[#{self.id}].#{data[:rest_class_method]} failed to update!"
                `console.error(error_message)`
              end
            end
          elsif record_class.record_cached?(data[:id])
            record_class._record_cache[data[:id].to_s]._update_record(data)
          elsif data[:destroyed]
            return
          end
        end
      end
    end
  end
end
