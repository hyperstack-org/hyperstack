if RUBY_ENGINE == 'opal'
  require 'react.js'
  require "react-server.js"
else
  require "react/rails/asset_variant"
  react_directory = React::Rails::AssetVariant.new(addons: true).react_directory
  Opal.append_path react_directory.untaint
  Opal.append_path File.expand_path('../../react-sources/', __FILE__).untaint
end
