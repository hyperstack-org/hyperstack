### Pusher-Fake Quickstart

The [Pusher-Fake](https://github.com/tristandunn/pusher-fake) gem will provide a transport using the same protocol as pusher.com.  You can use it to locally test an app that will be put into production using pusher.com.

#### 1 Add the Pusher, Pusher-Fake and HyperLoop gems to your Rails app

- add `gem 'pusher'` to your Gemfile.
- add `gem 'pusher-fake'` to the development and test sections of your Gemfile.

If you have not already installed the `hyper-react` and `hyper-mesh` gems, then do so now using the [hyper-rails](https://github.com/ruby-hyperloop/hyper-rails) gem.

- add `gem 'hyper-rails'` to your gem file (in the development section)
- run `bundle install`
- run `rails g hyperloop:install --all` (make sure to use the --all option)
- run `bundle update`

#### 2 Add the pusher js file to your application.js file

```ruby
# app/assets/javascript/application.js
...
//= require 'hyper-mesh/pusher'
//= require_tree .
Opal.load('components');
```

#### 3 Set the transport

Once you have HyperMesh, and pusher installed then add this initializer:
```ruby
# typically app/config/initializers/HyperMesh.rb
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
HyperMesh.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "HyperMesh"
  config.opts = {
    app_id: Pusher.app_id,
    key: Pusher.key,
    secret: Pusher.secret
  }.merge(PusherFake.configuration.web_options)
end
```

#### 4 Try It Out  

If you don't already have a model to play with,  add one now:

`bundle exec rails generate model Word text:string`

`bundle exec rake db:migrate`

Move `app/models/word.rb` to `app/models/public/word.rb` and move
`app/models/application_record.rb` to `app/models/public/application_record.rb`

**Leave** `app/models/model.rb` where it is.  This is your models client side manifest file.

Whatever model(s) you will plan to access on the client need to moved to the `app/models/public` directory.  This allows reactive-record to build a client side proxy for the models.  Models not moved will be completely invisible on the client side.

**Important** in rails 5 there is also a base `ApplicationRecord` class, that all other models are built from.  This class must be moved to the public directory as well.

If you don't already have a simple component to play with,  here is a simple one (make sure you added the Word model):

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

If you want to go into more details with the example check out [words-example](/docs/words-example.md)
