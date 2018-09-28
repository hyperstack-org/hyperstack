# Hyperstack::Configuration

This gem is used internally by other [Hyperstack](http://ruby-hyperstack.io) gems for keeping config settings, and for registering client side autoload requirements.

To indicate gems to be autoloaded on client side:

```ruby
require 'hyperstack-config'
Hyperstack.import 'my-gem-name'
Hyperstack.imports 'my-gem-name' # same as above
Hyperstack.import 'my-gem-name', server_only: true
Hyperstack.import 'my-gem-name', client_only: true
Hyperstack.import 'path', tree: true  # same as saying require_tree 'path' in a manifest file
Hyperstack.import_tree 'path' # same as above
Hyperstack.import 'asset_name' # same as saying require 'asset_name' in a manifest file
```

Once a gem file spec does a `Hyperstack.import` the listed gem will be automatically added to the `hyperstack-loader` manifest.   This means all you do is add a gem
to rails, and it will get sent on to the client (plus any other dependencies you care to require.)

The require method can be used in the hyperstack initializer as well to add code to the manifest (i.e. add a gem to that is not using Hyperstack.import)

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
    # value of transport is whatever the user set in the initializer,
    # you do what you want here...
  end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
