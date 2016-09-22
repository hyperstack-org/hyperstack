### Action Cable Quickstart

Action Cable has the most complicated underlying setup, but once you get through the configuration you will have a production ready transport.

#### 1 Get Rails 5

You need to be on rails 5 to use ActionCable.  Make sure you upgrade to rails 5 first.

#### 2 Add ReactRb

If you have not already installed the `reactrb` and `reactive-record` gems, then do so now using the [reactrb-rails-generator](https://github.com/reactrb/reactrb-rails-generator) gem.

- add `gem 'reactrb-rails-generator'` to your gem file (in the development section)
- run `bundle install`
- run `rails g reactrb:install --all` (make sure to use the --all option)
- run `bundle update`

#### 3 Add the synchromesh gem

- ~~add `gem 'synchromesh'` to your gem file~~  
- add `gem 'synchromesh', git: 'https://github.com/reactrb/synchromesh', branch: 'authorization-policies'`
- then `bundle install`  
- and in `app/views/components.rb` add `require 'synchromesh'`  
 immediately below`require 'reactive-record'`

#### 4 Set the transport

Once you have reactrb installed then add this initializer:
```ruby
#config/initializers/synchromesh.rb
Synchromesh.configuration do |config|
  config.transport = :action_cable
end
```

#### 5 Make sure caching is enabled

Synchromesh uses the rails cache to keep track of what connections are alive in a transport independent fashion.  Rails 5 by default will have caching off in development mode.

Check in `config/development.rb` and make sure that `cache_store` is never being set to `:null_store`.  

If you would like to be able to interact via
the `rails console` you should set the store to be something like this:

```ruby
# config/development.rb
Rails.application.configure do
  config.cache_store = :file_store, './rails_cache_dir'
end
```

ActionCable in `async` mode can only broadcast from the server.  If you change the database from a rails console, the console app will prepare the broadcast data, and then using an HTTP request will ship it the currently running server, which will then broadcast it.  In order to do this the console has to be able to access all the connection information, hence the need for a persistent cache like `file_store`.

Note:  If you are going to use the `redis` adapter with ActionCable you can use any non-null store.

[See this article for more details.](http://blog.bigbinary.com/2016/01/25/caching-in-development-environment-in-rails5.html)

#### 6 Define Your Policies

To start just open everything up by adding a policies directory and defining a policy file like this:

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  always_allow_connection
  regulate_all_broadcasts { |policy| policy.send_all }
  allow_change(to: :all, on: [:create, :update, :destroy]) { true }
end
```

#### 7 Setup ActionCable

If you are already using ActionCable in your app that is fine, as Synchromesh will not interfere with your existing connections.

Otherwise go through the following steps to setup ActionCable.

##### 7.1 Add the action_cable.js file

Include the `action_cable` js file in your assets

```javascript
//app/assets/javascripts/application.js
...
//= require action_cable
Opal.load('components');
```

#### 7.2 Make sure you have a cable.yml file

```yml
# config/cable.yml
development:
  adapter: async

test:
  adapter: async

production:
  adapter: redis
  url: redis://localhost:6379/1
```

#### 7.3 Set allowed request origins (optional)

By default action cable will only allow connections from localhost:3000 in development.  If you are going to something other than localhost:3000 you need to add something like this to your config:

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.action_cable.allowed_request_origins = ['http://localhost:3000', 'http://localhost:4000']
end
```

#### 8 Try It Out  

If you don't already have a model to play with,  add one now:

`bundle exec rails generate model Word text:string`

`bundle exec rake db:migrate`

Whatever model(s) you will plan to access on the client need to moved to the `app/models/public` directory.  This allows reactive-record to build a client side proxy for the models.  Models not moved will be completely invisible on the client side.

**Important** in rails 5 there is also a base `ApplicationRecord` class, that all other models are built from.  This class must be moved to the public directory as well.

If you don't already have a simple component to play with,  here is a simple one (make sure you add the Word model):

```ruby
# app/views/components/app.rb
class App < React::Component::Base

  def add_new_word
    # for fun we will use setgetgo.com to get random words!
    HTTP.get("http://randomword.setgetgo.com/get.php", dataType: :jsonp) do |response|
      Word.new(text: response.json[:Word]).save
    end
  end

  render(DIV) do
    SPAN { "Count of Words: #{Word.count}" }
    BUTTON { "add another" }.on(:click) { add_new_word }
    UL do
      Word.each { |word| LI { word.text } }
    end
  end
end
```

Add a controller:

```ruby
#app/controllers/test_controller.rb
class TestController < ApplicationController
  def app
    render_component
  end
end
```

Add the `test` route to your routes file:

```ruby
#app/config/routes.rb

  get 'test', to: 'test#app'

```

Fire up rails with `bundle exec rails s` and open your app in a couple of browsers.  As data changes you should see them all updating together.

You can also fire up a rails console, and then for example do a `Word.new(text: "Hello").save` and again see any browsers updating.

If you want to go into more details with example check out [words-example](/docs/words-example.md)
