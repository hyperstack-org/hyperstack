if RUBY_ENGINE == 'opal'
  %x{
    var ms = [
      "Warning: `react/react-source` is deprecated, ",
      "use `react/react-source-browser` or `react/react-source-server` instead."
    ]
    console.error(ms.join(""));
  }
  require 'react.js'
  require "react-server.js"
else
  require "hyperstack/internal/component"
  require "react/rails/asset_variant"
  variant = Hyperstack.env.production? ? :production : :development
  react_directory = React::Rails::AssetVariant.new({variant: variant}).react_directory
  Opal.append_path react_directory.untaint
end
