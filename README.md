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

## Basic Installation and Setup

The easiest way to install is to use the `hyper-rails` gem.

1. Add `gem 'hyper-rails'` to your Rails `Gemfile` development section.
2. Install the Gem: `bundle install`
3. Run the generator: `bundle exec rails g hyperloop:install --all`
4. Update the bundle: `bundle update`

Your Isomorphic Operations live in a `hyperloop/operations` folder and your server only Operations in `app/operations`

You will also find an `app/policies` folder with a simple access policy suited for development.  Policies are how you will provide detailed access control to your Isomorphic models.  

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-hyperloop/hyper-operation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code of Conduct](https://github.com/ruby-hyperloop/hyper-operation/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
