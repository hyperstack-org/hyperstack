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

            when opts[:resource_transport] == :action_cable
              opts[:action_cable_consumer] =
                `ActionCable.createConsumer.apply(ActionCable, #{[*opts[:action_cable_consumer_url]]})`
              Hyperloop.connect(*opts[:auto_connect])
            end
          end
        end

        def self.process_notification(data)
          record_class = Object.const_get(data[:record_type])
          if data[:scope]
            scope_fetch_state = record_class._class_fetch_states[data[:scope]]
            if scope_fetch_state == 'f'
              record_class._class_fetch_states[data[:scope]] = 'u'
              scope_name, scope_params = data[:scope].split('_[')
              if scope_params
                scope_params = '[' + scope_params
                record_class.send(data[:scope], JSON.parse(scope_params))
              else
                record_class.send(data[:scope])
              end
            end
          elsif record_class.record_cached?(data[:id])
            record = record_class.find(data[:id])
            record._update_record(data)
          end
        end
      end
    end
  end
end
