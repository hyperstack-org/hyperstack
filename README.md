# Hyperloop::Configuration

This gem is used internally by other [Hyperloop](http://ruby-hyperloop.io) gems for keeping config settings.

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
