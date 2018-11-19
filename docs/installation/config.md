# Configuration

Hyperstack configuration is set in an initializer.

> Note: You will need to stop and start your Rails server when changing this configuration.

Example configuration:

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  config.prerendering = :off

  config.import 'jquery', client_only: true
  config.import 'hyperstack/component/jquery', client_only: true
  config.import 'browser'
  config.import 'active_support'

  # config.import 'my-gem-name'
  # config.imports 'my-gem-name' # same as above
  # config.import 'my-gem-name', server_only: true
  # config.import 'my-gem-name', client_only: true
  # config.import 'path', tree: true  # same as saying require_tree 'path' in a manifest file
  # config.import_tree 'path' # same as above
  # config.import 'asset_name' # same as saying require 'asset_name' in a manifest file

  # Cancel importing React and ReactRouter if you are using Webpack
  # config.cancel_import 'react/react-source-browser'
  # config.cancel_import 'hyperstack/router/react-router-source'

  if Rails.env.development?
    config.import 'hyperstack/hotloader', client_only: true
    config.hotloader_port = 25222
  end
end
```

The listed gem will be automatically added to the `hyperstack-loader` manifest.   This means all you do is add a gem to Rails, and it will get sent on to the client (plus any other dependencies you care to require.)

The require method can be used in the Hyperstack initializer as well to add code to the manifest (i.e. add a gem to that is not using Hyperstack.import)

To define an initializer:

```ruby
module Hyperstack
  on_config_reset do
    # anything you want to run when initialization begins
  end

  on_config_initialized do
    # anything you want when initialization completes
  end

  define_setting :default_prerendering_mode, :on

  define_setting(:transport, :none) do |transport|
    # value of transport is whatever the user set in the initializer
    # you do what you want here...
  end
```
