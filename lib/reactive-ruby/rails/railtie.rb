module ReactiveRuby
  module Rails
    class Railtie < ::Rails::Railtie
      config.before_configuration do |app|
        app.config.assets.enabled = true
        app.config.assets.paths << ::Rails.root.join('app', 'views').to_s
        app.config.react.server_renderer =
          ReactiveRuby::ServerRendering::ContextualRenderer
        app.config.react.view_helper_implementation =
          ReactiveRuby::Rails::ComponentMount
      end
      config.after_initialize do
        # ::ApplicationController.class_eval do
        #   before_action do
        #     if params.has_key? 'hyperloop-prerendering'
        #       params['hyperloop-prerendering'].to_s == 'on'
        #     elsif params.has_key? 'hyperloop_prerendering'
        #       params['hyperloop_prerendering'].to_s == 'on'
        #     else
        #       Hyperloop.prerendering.to_s == 'on'
        #     end && next
        #     params[:no_prerender] = '1'
        #   end
        # end
        class ::HyperloopController < ::ApplicationController
          def action_missing(name)
            render_component
          end
        end
      end
    end
  end
end
