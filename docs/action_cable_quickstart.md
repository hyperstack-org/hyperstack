### Action Cable Quickstart

#### 1 Get Rails 5

You need to be on rails 5 to use action cable.  Make sure you upgrade to rails 5 first.

#### 2 Add ReactRb

If you have not already installed the `reactrb` and `reactive-record` gems, then do so now using the [reactrb-rails-generator](https://github.com/reactrb/reactrb-rails-generator) gem.

- add `gem 'reactrb-rails-generator'` to your gem file (in the development section)
- run `bundle install`
- run `rails g reactrb:install --all` (make sure to use the --all option)
- run `bundle update`

#### 3 Add the synchromesh gem

add `gem 'synchromesh'` to your gem file then
`bundle install`

and in `app/views/components.rb` replace `require 'reactive-record'` with `require 'synchromesh'`

#### 3 Set the transport

Once you have reactrb installed then add this initializer:

```ruby
#config/initializers/synchromesh.rb
Synchromesh.configuration do |config|
  config.transport = :action_cable
end
```

#### 4 Add the Action Cable js file

If you have not yet setup action cable then include the `action_cable` js file in your assets

```javascript
//app/assets/javascripts/application.js
...
//= require action_cable
...
```

If you are already using ActionCable in your app its fine, as Synchromesh will not interfere with your existing connections.

#### 5 Make sure you have a cable.yml file

...

#### 5 Make sure caching is enabled

Synchromesh uses the rails cache to keep track of what connections are alive in a transport independent fashion.  Rails 5 by default will have caching off in development mode.

Check in `config/development.rb` and make sure that cache_store is never being set to `:null_store`

[See this article for more details.](http://blog.bigbinary.com/2016/01/25/caching-in-development-environment-in-rails5.html)

#### 6 Define Your Policies

To start just open everything up by adding a policy directory and defining a policy file like this:

```ruby
# app/policies/application_policy
class ApplicationPolicy
  always_allow_connection
  regulate_all_broadcasts &:send_all
  allow_change(to: :all, for: [:create, :update, :destroy]) { true }
end
```

#### 7 Try It Out  

If you don't already have a model you can play with add one now:

`bundle exec rails generate model Article title:string text:text`
`bundle exec rake db:migrate`

Whatever model(s) you will use you need to move them to the `app/models/public` directory.  This allows reactive-record to build a client side proxy for the models.  Models not moved will be completely invisible on the client side.

**Important** in rails 5 there is also a base ApplicationRecord class, that all other models are built from.  This class must be moved to the public directory as well.

If you don't already have a simple component to play with,  make up one like this:

```ruby
# app/views/components/app.rb
class App < React::Component::Base
  # change Article to whatever your model name is
  render do
    div do
      "Count of MyModel: #{Article.all.count}".span
      " last id = #{Article.all.last.id}".span unless Article.all.count == 0
      button { "add another" }.on(:click) { Article.new.save }
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

Add add it to your routes file:

```ruby
#app/config/routes.rb

  get 'test', to: 'test#app'

```

Fire up rails: `bundle exec rails s` and away you go!
