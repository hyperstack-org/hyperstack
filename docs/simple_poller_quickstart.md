### Simple Poller Quickstart

The easiest way to get started is to use the built-in simple polling transport.

#### 1 Get yourself a rails app

Either take an existing rails app, or create a new one the usual way.

#### 2 Add ReactRb

If you have not already installed the `hyper-react` and `reactive-record` gems, then do so now using the [reactrb-rails-generator](https://github.com/hyper-react/reactrb-rails-generator) gem.

- add `gem 'reactrb-rails-generator'` to your gem file (in the development section)
- run `bundle install`
- run `bundle exec rails g hyper-react:install --all` (make sure to use the --all option)
- run `bundle update`

#### 3 Add the synchromesh gem

- add `gem 'synchromesh', git: 'https://github.com/hyper-react/synchromesh', branch: 'authorization-policies'`
- then `bundle install`  
- and in `app/views/components.rb` add `require 'hyper-mesh'`  
 immediately below`require 'reactive-record'`

#### 4 Set the transport

Once you have hyper-react installed then add this initializer:
```ruby
#config/initializers/synchromesh.rb
HyperMesh.configuration do |config|
  config.transport = :simple_poller
end
```

#### 5 Make sure caching is enabled

HyperMesh uses the rails cache to keep track of what connections are alive in a transport independent fashion.  Rails 5 by default will have caching off in development mode.

Check in `config/development.rb` and make sure that `cache_store` is never being set to `:null_store`.  

If you would like to be able to interact via
the `rails console` you should set the store to be something like this:

```ruby
# config/development.rb
Rails.application.configure do
  config.cache_store = :file_store, './rails_cache_dir'
end
```

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

#### 8 Try It Out  

If you don't already have a model to play with,  add one now:

`bundle exec rails generate model Word text:string`

`bundle exec rake db:migrate`

Whatever model(s) you will plan to access on the client need to moved to the `app/models/public` directory.  This allows reactive-record to build a client side proxy for the models.  Models not moved will be completely invisible on the client side.

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
