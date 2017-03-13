[ ![Codeship Status for ruby-hyperloop/hyper-store](https://app.codeship.com/projects/4454c560-d4ea-0134-7c96-362b4886dd22/status?branch=master)](https://app.codeship.com/projects/202301)

## Hyper-Store gem

Stores are where the state of your Application lives. Anything but a completely static web page will have dynamic states that change because of user inputs, the passage of time, or other external events.

**Stores are Ruby classes that keep the dynamic parts of the state in special state variables**

+ `Hyperloop::Store::Mixin` can be mixed in to any class to turn it into a Flux Store.
+ You can also create Stores by subclassing `Hyperloop::Store`.
+ Stores are built out of *reactive state variables*.
+ Components that *read* a Store's state will **automatically** update when the state changes.
+ All of your **shared** reactive state should be Stores - *The Store is the Truth*!
+ Stores can *receive* **dispatches** from *Operations*

## Documentation and Help

+ Please see the [ruby-hyperloop.io](http://ruby-hyperloop.io/) website for documentation.
+ Join the Hyperloop [gitter.io](https://gitter.im/ruby-hyperloop/chat) chat for help and support.

## Basic Installation and Setup

The easiest way to install is to use the `hyper-rails` gem.

1. Add `gem 'hyper-rails'` to your Rails `Gemfile` development section.
2. Install the Gem: `bundle install`
3. Run the generator: `bundle exec rails g hyperloop:install --all`
4. Update the bundle: `bundle update`

Your Isomorphic Operations live in a `hyperloop/stores` folder.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-hyperloop/hyper-store. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code of Conduct](https://github.com/ruby-hyperloop/hyper-store/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
