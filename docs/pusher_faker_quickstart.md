### Pusher-Fake Quickstart

The [Pusher-Fake](https://github.com/tristandunn/pusher-fake) gem will provide a transport using the same protocol as pusher.com.  You can use it to locally test an app that will be put into production using pusher.com.

#### 1 Add the Pusher, Pusher-Fake and HyperLoop gems to your Rails app

- add `gem 'pusher'` to your Gemfile.
- add `gem 'pusher-fake'` to the development and test sections of your Gemfile.

If you have not already installed the `hyper-component` and `hyper-model` gems, then do so now using the [hyper-rails](https://github.com/ruby-hyperloop/hyper-rails) gem.

- add `gem 'hyper-rails'` to your gem file (in the development section)
- run `bundle install`
- run `rails g hyperloop:install --all` (make sure to use the --all option)
- run `bundle update`

#### 2 Add the pusher js file to your application.js file

```ruby
# app/assets/javascript/application.js
...
//= require 'hyper-model/pusher'
//= require_tree .
Opal.load('components');
```

#### 3 Set the transport

Once you have Hyperloop, and pusher installed then add this initializer:
```ruby
# typically app/config/initializers/Hyperloop.rb
# or you can do a similar setup in your tests (see this gem's specs)
require 'pusher'
require 'pusher-fake'
# Assign any values to the Pusher app_id, key, and secret config values.
# These can be fake values or the real values for your pusher account.
Pusher.app_id = "MY_TEST_ID"      # you use the real or fake values
Pusher.key =    "MY_TEST_KEY"
Pusher.secret = "MY_TEST_SECRET"
# The next line actually starts the pusher-fake server (see the Pusher-Fake readme for details.)
require 'pusher-fake/support/base' # if using pusher with rspec change this to pusher-fake/support/rspec
# now copy over the credentials, and merge with PusherFake's config details
Hyperloop.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "Hyperloop"
  config.opts = {
    app_id: Pusher.app_id,
    key: Pusher.key,
    secret: Pusher.secret
  }.merge(PusherFake.configuration.web_options)
end
```

#### 4 Try It Out  

TODO include try_it_out partial
