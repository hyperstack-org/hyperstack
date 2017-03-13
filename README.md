# Hyperloop::Configuration

This gem is used internally by other [Hyperloop](http://ruby-hyperloop.io) gems for keeping config settings, and for registering client side autoload requirements.

To indicate gems to be autoloaded on client side:

```ruby
require 'hyperloop-config'
Hyperloop.require 'my-gem-name', gem: true
Hyperloop.require_gem 'my-gem_name' # short for above
Hyperloop.require_gem 'my-gem-name', server_only: true
Hyperloop.require_gem 'my-gem-name', client_only: true
Hyperloop.require 'path', tree: true  # same as saying require_tree 'path' in a manifest file
Hyperloop.require 'asset_name' # same as saying require 'asset_name' in a manifest file
```

The difference between `require_gem`, and `require` is that require_gem can be used inside a gem file spec.  

Once a gem file spec does a `Hyperloop.require_gem` the listed gem will be automatically added to the `hyperloop-loader` manifest.   This means all you do is add a gem
to rails, and it will get sent on to the client (plus any other dependencies you care to require.)

The require method can be used in the hyperloop initializer as well to add code to the manifest (i.e. add a gem to that is not using Hyperloop.require_gem)

To define an initializer:

```ruby
module Hyperloop
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
