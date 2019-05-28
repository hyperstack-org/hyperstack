module Hyperstack
  module Internal
    module Component
      module Rails
        class Railtie < ::Rails::Railtie
          config.before_configuration do |app|
            app.config.assets.enabled = true
            app.config.assets.paths << ::Rails.root.join('app', 'views').to_s
            app.config.react.server_renderer = ServerRendering::ContextualRenderer
            app.config.react.view_helper_implementation = ComponentMount
            ServerRendering::ContextualRenderer.asset_container_class = ServerRendering::HyperAssetContainer
          end
          config.after_initialize do
            class ::HyperstackController < ::ApplicationController
              def action_missing(*)
                parts = params[:action].split('__')
                render_component (parts[0..-2]+[parts.last.camelize]).join('::')
              end
            end
          end
        end
      end
    end
  end
end
