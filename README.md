# Synchromesh ![](logo.jpg?raw=true)

Synchromesh provides multi-client synchronization for [reactive-record.](https://github.com/catprintlabs/reactive-record)

In other words browser 1 creates, updates, or destroys a model, and the changes are broadcast to all other clients.

Add the gem, setup your configuration, and synchromesh does the rest.

## Transports

Currently there are two transport mechanisms:  

+ [Pusher](http://pusher.com) which gives you zero config websockets.  
+ Short cycle polling (for development)

As soon as Opal is working on Rails 5, we will add ActionCable.   

Also near term we will have a simple mechanism to plug in your own transport.

## Security [NOT IMPLEMENTED YET]

Synchromesh will build on top of ReactiveRecord's model-based permission mechanism:

Each *user* or *user group* will get a private transport channel.  Before broadcasting an update to a user's channel Synchromesh will filter the data based on that user's permissions.

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

Add `gem 'pusher'` to your gem file, and add `require synchromesh/pusher` to the client only portion of your components manifest.

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

## ActiveRecord Scope Enhancement

Because keeping data scopes synced as data changes is important (and difficult) Synchromesh adds some assist to the ActiveRecord `scope` macro.  You must use the `scope` macro (and not class methods) for things to work with Synchromesh.

The `scope` macro now takes an optional third parameter, with the following variations:

```ruby

class Todo < ActiveRecord::Base

  # Standard ActiveRecord form:
  # the proc will be evaluated as normal on the server, but also
  # will be used to update the scope as data changes on the client.
  # The client can only use simple "where" clauses that match attributes
  # to values.  
  scope :active, -> () { where(completed: true) }

  # For more complex scopes you can have different server and client procs:
  # In this form the 3rd param is the proc that is executed on the client to determine
  # if the changed (or new) record now should remain, be added, or removed from the scope.
  # If the value returned by the proc is truthy, then the record will be added (or remain)
  # in the scope.  Otherwise it will be removed from the scope.
  scope :with_recent_comments,
        -> () { joins(:comments).where('created_at >= ?', Time.now-1.week) }   # server
        -> () { comments.detect { |order| order.created_at >= Time.now-1.week }} # client
  # Note that while this may seem inefficient, the work is spread over each client, and the
  # client side scope proc will only be executed on clients that are currently observing that
  # scope.

  # Sometimes its just better to let the scope be computed on the server:
  scope :complex_todo, :no_client_sync, -> () { ... big complex sql ... }
  # In this case any clients that need to know if the scope is changed will make a followup
  # request to the server to get the new scope.

  # Or you can declare an entire model to have all its scopes computed on the server:
  no_client_sync
  # Now all following scope declarations will be computed on server
  # unless they explicitly have two procs

end
```

## Development

Specs run in rspec/capybara/selenium. To run do:

```
bundle exec rspec
```

You can run the specs in firefox by adding `DRIVER=ff` (best for debugging.)  You can add `SHOW_LOGS=true` if running in poltergeist (the default) to see what is going on, but ff is a lot better.

## How it works

The design goal is to push as much work onto the client side as possible.

* `ActiveRecord` after_commit hooks are used to broadcast changes and deletions to all participating clients.
* Each client then hooks into the underlying `Reactive-Record` mechanism as if the change was made locally, but *already* saved.
* `Reactive-Record` then updates scopes, and notifies `React` of the state changes as it would for any other change.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reactive-ruby/synchromesh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
