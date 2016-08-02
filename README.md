# Synchromesh ![](logo.jpg?raw=true)

Synchromesh provides multi-client synchronization for [reactive-record](https://github.com/catprintlabs/reactive-record)

In other words browser 1 creates, updates, or destroys a model, and the changes are broadcast to all other clients.

Add the gem, setup your configuration, and synchromesh does the rest.

## Transports

Currently there are three transport mechanisms:  

+ [Pusher](http://pusher.com) which gives you zero config websockets.  
+ [PusherFake](https://github.com/tristandunn/pusher-fake) which
+ Short cycle polling (for development)

As soon as Opal is working on Rails 5, we will add ActionCable.   

Also near term we will have a simple mechanism to plug in your own transport.

## Security [NOT IMPLEMENTED YET]

Synchromesh builds on top of ReactiveRecord's model-based permission mechanism:

Each *user* or *user group* gets a private transport channel.  Before broadcasting an update to a user's channel Synchromesh filters the data based on that user's permissions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'synchromesh'
```

And then execute:

    $ bundle install

Also you must `require 'synchromesh'` from your client side code.  The easiest way is to
find the `require 'reactive-record'` line (typically in `components.rb`) and add `require 'synchromesh'` directly below it.  

## Configuration

Add an initializer like this:

```ruby
# for rails this would go in: config/initializers/synchromesh.rb
Synchromesh.configuration do |config|

  config.transport = :pusher # set to :none to turn off, or to :simple_poller (see below)
  config.opts = { ... transport specific options ...}
  config.channel_prefix = 'synchromesh'
  # config.client_logging = false                         # default is true
end
```

### Pusher Configuration Specifics

Add `gem 'pusher'` to your gem file, and and `require synchromesh/pusher` to the client only portion of your components manifest.

```ruby
# typically config/initializers/synchromesh.rb
Synchromesh.configuration do |config|
  config.transport = :pusher
  config.opts = {
    app_id: '2xxxx2',
    key:    'dxxxxxxxxxxxxxxxxxx9',
    secret: '2xxxxxxxxxxxxxxxxxx2',
    encrypted: false # optional defaults to true
  }
  config.channel_prefix = 'syncromesh' # or any other string you want
end
```

### Pusher-Fake

You can also use the [Pusher-Fake](https://github.com/tristandunn/pusher-fake) gem while in development.  Setup is a little tricky.  First
add `gem 'pusher-fake'` to the development and/or test section of your gem file. Then setup your config file:

```ruby
# typically config/initializers/synchromesh.rb
# or you can do a similar setup in your tests (see this gem's specs)
require 'pusher'
require 'pusher-fake'
# The app_id, key, and secret need to be assigned directly to Pusher
# so PusherFake will work.
Pusher.app_id = "MY_TEST_ID"      # you use the real or fake values
Pusher.key =    "MY_TEST_KEY"
Pusher.secret = "MY_TEST_SECRET"
# The next line actually starts the pusher-fake server (see the Pusher-Fake readme for details.)
require 'pusher-fake/support/rspec'
# now copy over the credentials, and merge with PusherFake's config details
Synchromesh.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "synchromesh"
  config.opts = {
    app_id: Pusher.app_id,
    key: Pusher.key,
    secret: Pusher.secret
  }.merge(PusherFake.configuration.web_options)
end
```

### Simple Poller

Setup your config like this:
```ruby
Synchromesh.configuration do |config|
  config.transport = :simple_poller
  config.channel_prefix = "synchromesh"
  config.opts = {
    seconds_between_poll = 5, # default is 0.5 you may need to increase if testing with Selenium
    seconds_polled_data_will_be_retained = 1.hour  # clears channel data after this time, default is 5 minutes
  }
end
```

## Development

TBD

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reactive-ruby/synchromesh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
