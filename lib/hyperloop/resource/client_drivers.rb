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


      end
    end
  end
end
