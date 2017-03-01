### PusherQuickstart

[Pusher.com](https://pusher.com/) provides a production ready push transport for your App.  You can combine this with [Pusher-Fake](/docs/pusher_faker_quickstart.md) for local testing as well.  You can get a free pusher account and API keys at [https://pusher.com](https://pusher.com)

#### 1 Add the Pusher and HyperLoop gems to your Rails app

- add `gem 'pusher'` to your Gemfile.

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

Once you have Hyperloop and pusher installed then add this initializer:
```ruby
# config/initializers/Hyperloop.rb
Hyperloop.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "Hyperloop"
  config.opts = {
    app_id: "2....9",
    key: "f.....g",
    secret: "1.......3"
  }
end
```

#### 4 Try It Out  

TODO add try_it_out partial
