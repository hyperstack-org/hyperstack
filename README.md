# Synchromesh ![](logo.jpg?raw=true)

[Synchromesh](https://en.wikipedia.org/wiki/Manual_transmission#Synchromesh) provides multi-client synchronization for [reactive-record.](https://github.com/catprintlabs/reactive-record)

In other words browser 1 creates, updates, or destroys a model, and the changes are broadcast to all other clients.

Add the gem, setup your configuration, and synchromesh does the rest.

## Transports

Currently there are two transport mechanisms:  

+ [Pusher](http://pusher.com) which gives you zero config websockets.  
+ Short cycle polling (for development)

Hopefully very shortly we will also have an ActionCable transport.   

Also near term we will have a simple mechanism to plug in your own transport.

## Authorization

Each application defines a number of *channels* and *authorization policies* for those channels and the data sent over them.

Policies are defined with *Policy* classes.  These are similar and compatible with [Pundit](https://github.com/elabs/pundit) but
you do not need to use the pundit gem.

Examples:

```ruby
class ApplicationPolicy
  # define policies for the Application

  # all clients can connect to the Application
  always_allow_connection
end

class ProductionCenterPolicy
  # define policies for the ProductionCenter model

  # any time a ProductionCenter model is updated
  # broadcast the total_jobs_shipped attribute over the
  # application channel (i.e. this is public data anybody can see)
  regulate_broadcast do |policy|
    policy.send_only(:total_jobs_shipped).to(Application)
  end
end

class UserPolicy
  # define policies for the User channel and Model

  # connect a channel for each logged in user
  regulate_instance_connection { self }

  # users can see all but one field of their own data
  regulate_broadcast do |policy|
    policy.send_all_but(:gross_margin_contribution).to(self)
  end
end
```

For complete details see [Authorization Policies](authorization-policies.md)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'synchromesh'
```

And then execute:

    $ bundle install

Also you must `require 'synchromesh'` from your client side code.  The easiest way is to
find the `require 'reactive-record'` line (typically in `components.rb`) and add `require 'synchromesh'` directly below it.  

## Configuration

Add an initializer like this:

```ruby
# for rails this would go in: config/initializers/synchromesh.rb
Synchromesh.configuration do |config|
  config.transport = :simple_poller # or :none, action_cable, :pusher - see below)
end
# for a minimal setup you will need to define at least one channel, which you can do
# in the same file as your initializer.
# Normally you would put these policies in the app/policies/ directory
class ApplicationPolicy
  # allow all clients to connect to the Application channel
  regulate_connection { true }
  # broadcast all model changes over the Application channel *DANGEROUS*
  regulate_all_broadcasts { |policy| policy.send_all }
end
```

### Action Cable Configuration

If you are on Rails 5 you can use ActionCable out of the box.

```ruby
#config/initializers/synchromesh.rb
Synchromesh.configuration do |config|
  config.transport = :action_cable
end
```

In addition make sure that you include the `action_cable` js file in your assets

```javascript
//application.js
...
//= require action_cable
...
```

The rest of the setup will be handled by Synchromesh.

Synchromesh will not interfere with any ActionCable connections and channels you may have already defined.  

### Pusher Configuration

Add `gem 'pusher'` to your gem file, and add `//= require 'synchromesh/pusher'` to your application.js file.

```ruby
# typically config/initializers/synchromesh.rb
Synchromesh.configuration do |config|
  config.transport = :pusher
  config.opts = {
    app_id: '2xxxx2',
    key:    'dxxxxxxxxxxxxxxxxxx9',
    secret: '2xxxxxxxxxxxxxxxxxx2',
    encrypted: false # optional defaults to true
  }
  config.channel_prefix = 'syncromesh' # or any other string you want
end
```

### Pusher-Fake

You can also use the [Pusher-Fake](https://github.com/tristandunn/pusher-fake) gem while in development.  Setup is a little tricky.  First
add `gem 'pusher-fake'` to the development and/or test section of your gem file. Then setup your config file:

```ruby
# typically config/initializers/synchromesh.rb
# or you can do a similar setup in your tests (see this gem's specs)
require 'pusher'
require 'pusher-fake'
# The app_id, key, and secret need to be assigned directly to Pusher
# so PusherFake will work.
Pusher.app_id = "MY_TEST_ID"      # you use the real or fake values
Pusher.key =    "MY_TEST_KEY"
Pusher.secret = "MY_TEST_SECRET"
# The next line actually starts the pusher-fake server (see the Pusher-Fake readme for details.)
require 'pusher-fake/support/base' # if using pusher with rspec change this to pusher-fake/support/rspec
# now copy over the credentials, and merge with PusherFake's config details
Synchromesh.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "synchromesh"
  config.opts = {
    app_id: Pusher.app_id,
    key: Pusher.key,
    secret: Pusher.secret
  }.merge(PusherFake.configuration.web_options)
end
```

### Simple Poller Details

Setup your config like this:
```ruby
Synchromesh.configuration do |config|
  config.transport = :simple_poller
  config.channel_prefix = "synchromesh"
  config.opts = {
    seconds_between_poll = 5, # default is 0.5 you may need to increase if testing with Selenium
    seconds_polled_data_will_be_retained = 1.hour  # clears channel data after this time, default is 5 minutes
  }
end
```

## ActiveRecord Scope Enhancement

When the client receives notification that a record has changed Synchromesh finds the set of currently rendered scopes that might be effected, and requests them to be updated from the server.  

To give you control over this process Synchromesh adds some features to the ActiveRecord scope macro.  Note you must use the `scope` macro (and not class methods) for things to work with Synchromesh.

The `scope` macro now takes an optional third parameter and an optional block:

```ruby

class Todo < ActiveRecord::Base

  # Standard ActiveRecord form:
  # the proc will be evaluated as normal on the server, and as needed updates
  # will be requested from the clients
  scope :active, -> () { where(completed: true) }
  # In the simple form the scope will be reevaluated if the model that is
  # being scoped changes, and if the scope is currently being used to render data.

  # If the scope joins with other data you will need to specify this by
  # passing an array of the joined models:
  scope :with_recent_comments,
        -> () { joins(:comments).where('created_at >= ?', Time.now-1.week) },
        [Comments]
  # Now with_recent_comments will be re-evaluated whenever Comments or Todo records
  # change.  The array can be the second or third parameter.

  # It is possible to optimize when the scope is re-evaluated by attaching a block to
  # the scope.  If the block returns true, then the scope will be re-evaluated.
  scope :active, -> () { where(completed: true) } do |record|
    (record.completed.nil? && record.destroyed?) || record.previous_changes[:completed]
  end
  # In other words only reevaluate if an "uncompleted" record was destroyed or if
  # the completed attribute has changed.  Note the use of the ActiveRecord
  # previous_changes method.  Also note that the attributes in record are "after"
  # changes are made unless the record is destroyed.

  # For heavily used scopes you can even update the scope manually on the client
  # using the second parameter passed to the block:
  scope :active, -> () { where(completed: true) } do |record, collection|
    if (record.completed.nil? && record.destroyed?) ||
       (record.completed && record.previous_changes[:completed])
      collection.delete(record)
    elsif record.completed && record.previous_changes[:completed]
      collection << record
    end
    nil # return nil so we don't resync the scope from the server
  end

  # The 'joins-array' applies to the block as well.  in other words if no joins
  # array is provided the block will only be called if records for scoped model
  # change.  If an array is provided, then the additional models will be added
  # to the join filter.  However if any empty array is provided all changes will
  # passed.
  scope :scope1, [AnotherModel], -> () {...} do |record|
    # record will be either a Todo, or AnotherModel
  end

  scope :scope2, [], -> () { ... } do |record|
    # any change to any model will be passed to the block
  end

  # The empty join array can also be used to prevent a scope from ever being
  # updated:
  scope :never_synced_scope, [], -> () { ... }

  # Or if you prefer just pass any non-array value of your choice:
  scope :never_synced_scope, :no_sync, -> () {...}

end
```

## Common Errors

- no policy file
- wrong version of pusher-fake  (pusher-fake/base vs. pusher-fake/rspec)
- forgetting to add require pusher in components manifest  results in error like this:

Exception raised while rendering #<TopLevelRailsComponent:0x53e>
    ReferenceError: Pusher is not defined

- no create/update/destroy policies
you won't see much on the console: but if you look at the response from the server you will see success is false
- using for: :all instead of to: :all (should fix this)

## Development

Specs run in rspec/capybara/selenium. To run do:

```
bundle exec rspec spec
```

You can run the specs in firefox by adding `DRIVER=ff` (best for debugging.)  You can add `SHOW_LOGS=true` if running in poltergeist (the default) to see what is going on, but ff is a lot better for debug.

## How it works

The design goal is to push as much work onto the client side as possible.

* `ActiveRecord` after_commit hooks are used to broadcast changes and deletions to all participating clients.
* Each client then searches for any scopes currently being rendered that will need to be
updated.
* `Reactive-Record` then updates scopes, and notifies `React` of the state changes as it would for any other change.



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reactive-ruby/synchromesh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
