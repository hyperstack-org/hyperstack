if defined?(Rails)
  require 'action_view'
  require 'react-rails'
  require 'hyperstack/internal/component/rails'
  require 'hyperstack/internal/component/rails/server_rendering/hyper_asset_container'
  require 'hyperstack/internal/component/rails/server_rendering/contextual_renderer'
  require 'hyperstack/internal/component/rails/component_mount'
  require 'hyperstack/internal/component/rails/railtie'
  require 'hyperstack/internal/component/rails/controller_helper'
  require 'hyperstack/internal/component/rails/component_loader'
end
