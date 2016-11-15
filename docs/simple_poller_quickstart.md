### Simple Poller Quickstart

The easiest push transport is the built-in simple poller.  This is great for demos or trying out HyperMesh but because it is constantly polling it is not suitable for production systems or any kind of real debug or test activities.

#### 1 Add the HyperLoop gems to your Rails app

If you have not already installed the `hyper-react` and `hyper-mesh` gems, then do so now using the [hyper-rails](https://github.com/ruby-hyperloop/hyper-rails) gem.

- add `gem 'hyper-rails'` to your gem file (in the development section)
- run `bundle install`
- run `rails g hyperloop:install --all` (make sure to use the --all option)
- run `bundle update`

#### 2 Set the transport

Once you have HyperMesh installed then add this initializer:
```ruby
#config/initializers/synchromesh.rb
HyperMesh.configuration do |config|
  config.transport = :simple_poller
  # options
  # config.opts = {
  #   seconds_between_poll: 5, # default is 0.5 you may need to increase if testing with Selenium
  #   seconds_polled_data_will_be_retained: 1.hour  # clears channel data after this time, default is 5 minutes
  # }
end
```

#### 3 Try It Out  

If you don't already have a model to play with add one now:

`bundle exec rails generate model Word text:string`

`bundle exec rake db:migrate`

Move `app/models/word.rb` to `app/models/public/word.rb`

**Leave** `app/models/model.rb` where it is.  This is your models client side manifest file.

Whatever model(s) you will plan to access on the client need to moved to the `app/models/public` directory.  This allows reactive-record to build a client side proxy for the models.  Models not moved will be completely invisible on the client side.

**Important** in rails 5 there is also a base `ApplicationRecord` class, that all other models are built from.  This class must be moved to the public directory as well.

If you don't already have a component to play with,  here is a simple one (make sure you added the Word model):

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
