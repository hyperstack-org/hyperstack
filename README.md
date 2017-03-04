#  Hyper-Model

[![Join the chat at https://gitter.im/reactrb/chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/reactrb/chat?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Gem Version](https://badge.fury.io/rb/hyper-mesh.svg)](https://badge.fury.io/rb/hyper-mesh)

## Hyper-Model gem

The Hyper-Model gem extends your ActiveRecord Models to your Isomorphic code so they are accessible from the client or server.

Hyperloop Components, Operations, and Stores have CRUD access to your server side ActiveRecord Models, using the standard ActiveRecord API.

In addition, Hyperloop implements push notifications (via a number of possible technologies) so changes to records on the server are dynamically pushed to all authorized clients.

In other words, one browser creates, updates, or destroys a Model, and the changes are persisted in ActiveRecord models and then broadcast to all other authorized clients.

+ Please see the [ruby-hyperloop.io](http://ruby-hyperloop.io/) website for documentation.
+ Join the Hyperloop [gitter.io](https://gitter.im/ruby-hyperloop/chat) chat for help and support


### Basic Installation and Setup

The easiest way to install is to use the `hyper-rails` gem.

1. Add `gem 'hyper-rails'` to your Rails `Gemfile` development section.
2. Install the Gem: `bundle install`
3. Run the generator: `bundle exec rails g hyperloop:install --all`
4. Update the bundle: `bundle update`

You will find a `hyperloop/models` folder has been added to Rails.  To access a model on the client, move it into the `hyperloop/models` folder.  If you are on Rails 5, you will also need to move the `application_record.rb` into this folder.

You will also find an `app/policies` folder with a simple access policy suited for development.  Policies are how you will provide detailed access control to your Isomorphic models.  

To summarize:

+ Your Isomorphic Models are moved to `hyperloop/models`. These are accessible to your Components, Operations, and Stores from either the server or the client.
+ If you need to have server-only Models, they remain in `app/models`. These models are **not** accessible to your Isomorphic code.

### Setting up the Push Transport

To have changes to your Models on the server broadcast to authorized clients, add a Hyperloop initializer file and specify a transport.  For example to setup a simple polled transport add this file:


```ruby
# config/initializers/hyperloop.rb
Hyperloop.configuration do |config|
  config.transport = :simple_poller
end
```

After restarting, and reloading your browsers you will see changes broadcast to the clients.  You can also play with this by firing up a rails console, and creating, changing or destroying Models at the console.

For setting up the other possible transports (Action Cable, Pusher.com, Pusher Fake) please see the [Hyperloop website](http://ruby-hyperloop.io/).

## Development

`hyper-model` is the merger of `reactive-record`, `synchromesh` and `hyper-mesh` gems.  As such a lot of the internal names are still using either ReactiveRecord or Synchromesh module names.

The original `ReactiveRecord` specs were written in opal-rspec.  These are being migrated to use server rspec with isomorphic helpers.  There are about 150 of the original tests left and to run these you

1. cd to `reactive_record_test_app`
2. do a bundle install/update as needed,
3. `bundle exec rake db:reset`,
4. start the server: `bundle exec rails s`,
5. then visit `localhost:3000/spec-opal`.

If you want to help **PLEASE** consider spending an hour and migrate a spec file to the new format.  You can find examples by looking in the `spec/reactive_record/` directory and matching to the original file in

`reactive_record_test_app/spec_dont_run/moved_to_main_spec_dir`

The remaining tests are run in the more traditional `bundle exec rake`

or

```
bundle exec rspec spec
```

You can run the specs in firefox by adding `DRIVER=ff` (best for debugging.)  You can add `SHOW_LOGS=true` if running in poltergeist (the default) to see what is going on, but ff is a lot better for debug.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reactive-ruby/HyperMesh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
