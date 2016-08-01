# Synchromesh ![](logo.jpg?raw=true)

Synchromesh provides multi-client synchronization for [reactive-record](https://github.com/catprintlabs/reactive-record)

In otherwords browser 1 creates, updates, or destroys a model, and the changes are broadcast to all other clients.

Add the gem, setup the configuration, and synchromesh does the rest.

## Transports

Currently there are two transport mechanisms:  

+ [Pusher](http://pusher.com) which gives you zero config websockets.  
+ Short cycle polling (for development)

As soon as Opal is working on Rails 5, we will add ActionCable.   

Also near term we will have a simple mechanism to plug in your own transport.

## Security [NOT IMPLEMENTED YET]

Synchromesh builds on top of ReactiveRecord's model-based permission mechanism:

Each *user* gets a private transport channel.  Before broadcasting an update to a users channel Synchromesh filters the data based on that users permissions.

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

  config.app_id =         '2xxxx2'
  config.key =            'dxxxxxxxxxxxxxxxxxx9'
  config.secret =         '2xxxxxxxxxxxxxxxxxx2'
  config.channel_prefix = 'synchromesh'                   # this can be any string

  # config.client_logging = false                         # default is true

  # simple_poller - good for debug or while developing on a plane... does NOT use long polling, so is not
  # workable for production

  # config.transport = :simple_poller
  # config.seconds_between_poll = 5                       # default is 0.5
  # config.seconds_polled_data_will_be_retained = 1.hour  # clears channel data after this time, default is 5 minutes,

end
```

## Development

TBD

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reactive-ruby/synchromesh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
