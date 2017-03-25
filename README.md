#  Hyper-Operation

## Hyper-Operation gem

Operations encapsulate business logic. In a traditional MVC architecture, Operations end up either in Controllers, Models or some other secondary construct such as service objects, helpers, or concerns. Here they are first class objects. Their job is to mutate state in the Stores and Models.

+ Hyperloop::Operation is the base class for Operations.
+ An Operation orchestrates the updating of the state of your system.
+ Operations also wrap asynchronous operations such as HTTP API requests.
+ Operations serve the role of both Action Creators and Dispatchers described in the Flux architecture.
+ Operations also serve as the bridge between client and server. An operation can run on the client or the server, and can be invoked remotely.

## Documentation and Help

+ Please see the [ruby-hyperloop.io](http://ruby-hyperloop.io/) website for documentation.
+ Join the Hyperloop [gitter.io](https://gitter.im/ruby-hyperloop/chat) chat for help and support.

## Installation and Setup

**Note: Operations require Rails currently.**

### Easy Installation

The easiest way to install is to use the `hyper-rails` generator.

1. Add `gem 'hyper-rails'` to your Rails `Gemfile` development section.
2. Install the Gem: `bundle install`
3. Run the generator: `bundle exec rails g hyperloop:install --all`
4. Update the bundle: `bundle update`

### Manual Installation

Add `gem 'hyper-operation'` to your Gemfile
Add `//= require hyperloop-loader` to your application.rb

If you want operations to interact between server and client you will have to pick a transport:
```ruby
# initializers/hyperloop.rb
Hyperloop.configuration do |config|

  # to use Action Cable
    config.transport = :action_cable # for rails 5+

  # to use Pusher (see www.pusher.com)
    config.transport = :pusher
    config.opts = {
      app_id: "pusher application id",
      key: "pusher public key",
      secret: "pusher secret key"
    }

  # to use Pusher Fake (creates a fake pusher service)
    # Its a bit weird:  You have to define require pusher and
    # define some FAKE pusher keys first, then bring in pusher-fake
    # the actual key values don't matter just the order!!!
    require 'pusher'  
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"      # don't bother changing these strings
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require 'pusher-fake/support/base'
    # then setup your config like pusher but merge in the pusher fake
    # options
    config.transport = :pusher
    config.opts = {
      app_id: Pusher.app_id,
      key: Pusher.key,
      secret: Pusher.secret
    }.merge(PusherFake.configuration.web_options)

  # For down and dirty simplicity use polling:
    config.transport = :simple_poller
    # change this to slow down polling, default is much faster
    # and hard to debug
    config.opts = { seconds_between_poll: 2 }
end
```

You will also have to add at least one channel policy to authorize the connection between clients and the server.

```ruby
# app/policies/application_policy.rb
class Hyperloop::ApplicationPolicy
  # allow any client too attach to the Hyperloop::Application for example
  always_allow_connection  
end
```

See the [Channels](#channels) section for more details on authorization.

### Add the engine

```ruby
# config/routes.rb
mount Hyperloop::Engine => '/hyperloop'
```

### Operation Folder Structure

Your Isomorphic Operations live in a `app/hyperloop/operations` folder and your server only Operations in `app/operations`

You will also find an `app/policies` folder with a simple access policy suited for development.  Policies are how you will provide detailed access control to your Isomorphic models.  

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-hyperloop/hyper-operation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code of Conduct](https://github.com/ruby-hyperloop/hyper-operation/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
