module ReactiveRuby
  module Rails
    class Railtie < ::Rails::Railtie
      config.before_configuration do |app|
        if config.respond_to?(:assets)
          app.config.assets.enabled = true
          app.config.assets.paths << ::Rails.root.join('app', 'views').to_s
        else
          Opal.append_path ::Rails.root.join('app', 'views').to_s
        end
        app.config.react.server_renderer = ReactiveRuby::ServerRendering::ContextualRenderer
        app.config.react.view_helper_implementation = ReactiveRuby::Rails::ComponentMount
        ReactiveRuby::ServerRendering::ContextualRenderer.asset_container_class = ReactiveRuby::ServerRendering::HyperAssetContainer
      end
      config.after_initialize do
        class ::HyperloopController < ::ApplicationController
          def action_missing(name)
            render_component
          end
        end
      end
    end
  end
end
