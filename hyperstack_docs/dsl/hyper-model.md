# HyperModel

# Work in progress - ALPHA (docs and code)

In Hyperstack, your ActiveRecord Models are available in your Isomorphic code.

Components, Operations, and Stores have CRUD access to your server side ActiveRecord Models, using the standard ActiveRecord API.

In addition, Hyperstack implements push notifications (via a number of possible technologies) so changes to records on the server are dynamically pushed to all authorized clients.

In other words, one browser creates, updates, or destroys a Model, and the changes are persisted in ActiveRecord models and then broadcast to all other authorized clients.

+ You access your Model data in your Components, Operations, and Stores just like you would on the server or in an ERB or HAML view file.
+ If an optional push transport is connected Hyperstack broadcasts any changes made to your ActiveRecord models as they are persisted on the server or updated by one of the authorized clients.
+ Some Models can be designated as *server-only* which means they are not available to the Isomorphic code.

For example, consider a simple model called `Dictionary` which might be part of Wiktionary type app.

```ruby
class Dictionary < ActiveRecord::Base

  # attributes
  #   word: string   
  #   definition: text
  #   pronunciation: string

  scope :defined, -> { 'definition IS NOT NULL AND pronunciation IS NOT NULL' }
end
```

Here is a very simple Hyperstack Component that shows a random word from the dictionary:

```ruby
class WordOfTheDay < Hyperstack::Component

  def pick_entry!  
    # pick a random word and assign the selected record to entry
    @entry = Dictionary.defined.all[rand(Dictionary.defined.count)]
    force_update! # redraw our component when the word changes
    # Notice that we use standard ActiveRecord constructs to select our
    # random entry value
  end

  # pick an initial entry before we mount our component...
  before_mount :pick_entry

  # Again in our render block we use the standard ActiveRecord API, such
  # as the 'defined' scope, and the 'word', 'pronunciation', and
  # 'definition' attribute getters.  
  render(DIV) do
    DIV { "total definitions: #{Dictionary.defined.count}" }
    DIV do
      DIV { @entry.word }
      DIV { @entry.pronunciation }
      DIV { @entry.definition }
      BUTTON { 'pick another' }.on(:click) { pick_entry! }
    end
  end
```

For complete examples with *push* updates, see any of the apps in the `examples` directory, or build your own in 5 minutes following one of the quickstart guides:

## Isomorphic Models

Depending on the architecture of your application, you may decide that some of your models should be Isomorphic and some should remain server-only. The consideration will be that your Isomorphic models will be compiled by Opal to JavaScript and accessible on he client (without the need for a boilerplate API) - Hyperstack takes care of the communication between your server-side models and their client-side compiled versions and you can use Policy to govern access to the models.

In order for Hyperstack to see your Models (and his make them Isomorphic) you need to move them to the `hyperstack/models` folder. Only models in this folder will be seen by Hyperstack and compiled to Javascript. Once a Model is on this folder it ill be accessable to both your client and server code.

| **Location of Models**        | **Scope**           |
| ------------------------- |---------------|
| `app\models` | Server-side code only |
| `app\Hyperstack\models` | Isomorphic code (client and server) |

### Rails 5.1.x

Upto Rails 4.2, all models inherited from `ActiveRecord::Base`. But starting from Rails 5, all models will inherit from `ApplicationRecord`.

To accommodate this change, the following file has been automatically added to models in Rails 5 applications.

```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
```

For Hyperstack to see this change, this file needs to be moved (or copied if you have some server-side models) to the `apps/Hyperstack` folder.

### Explicit Scope Access

In order to prevent unauthorized access to information like scope counts, lists of record ids, etc, Hyperstack now (see issue https://github.com/ruby-Hyperstack/hyper-mesh/issues/43) requires you explicitly allow scopes to be viewed on the client, otherwise you will get an AccessViolation.

To globally allow access to all scopes add this to the ApplicationRecord class

```ruby
class ApplicationRecord < ActiveRecord::Base
  regulate_scope :all
end
```

## ActiveRecord API

Hyperstack uses a subset of the standard ActiveRecord API to give your Isomorphic Components, Operations and Stores access to your server side Models.  As much as possible Hyperstack follows the syntax and semantics of ActiveRecord.  

### Interfacing to React

Hyperstack integrates with React (through Components) to deliver your Model data to the client without you having to create extra APIs or specialized controllers.  The key idea of React is that when state (or params) change, the portions of the display effected by this data will be updated.

Hyperstack automatically creates React state objects that will be updated as server side data is loaded or changes.  When these states change the associated parts of the display will be updated.

A brief overview of how this works will help you understand the how Hypeloop gets the job done.

#### Rendering Cycle

On the UI you will be reading models in order to display data.

If during the rendering of the display the Model data is not yet loaded, placeholder values (the default values from the `columns_hash`) will be returned by Hyperstack.  

Hyperstack then keeps track of where these placeholders (or `DummyValue`s) are displayed, and when they do get loaded, those parts of the display will re-render.

If later the data changes (either due to local user actions, or receiving push updates) then again any parts of the display that were dependent on the current values will be re-rendered.

You normally do not have to be aware of this.  Just access your Models using the normal scopes and finders, then compute values and display attributes as you would on the server.  Initially the display will show the placeholder values and then will be replaced with the real values.

#### Prerendering

During server-side pre-rendering, Hyperstack has direct access to the server so on initial page load all the values will be loaded and present.  

#### Lazy Loading

Hyperstack lazy loads values, and does not load any thing until an explicit displayable value is requested.  For example `Todo.all` will have no action, but `Todo.all.pluck[:title]` will return an array of titles.

At the end of the rendering cycle the set of all values requested will be merged into a tree structure and sent to the server, returning the minimum amount of data needed.

#### Load Cycle Methods

There are a number of methods that allow you to interact with this load cycle when needed.  These are documented [below](#other-methods-for-interacting-with-the-load-and-render-cycle).

### Class Methods

#### New and Create

`new`: Takes a hash of attributes and initializes a new unsaved record.  The values of any attributes not specified in the hash will be taken from the Models default values specified in the `columns_hash`.

If `new` is passed a native javascript object it will be treated as a hash and converted accordingly.

`create`: Short hand for `new(...).save`.  See the `save` instance method for details on how saving is done.

#### Scoping and Finding

`scope` and `default_scope`:  Hyperstack adds four new options to these methods: `joins`, `client`, `select` and `server`.  The `joins` option provides information on how the scope will be joined with other models.  The `client` and `select` options allow scoping to be done on the client side to offload this from the server, and the `server` option is there just for symmetry with the other options.

```ruby
# the active scope proc is executed on the server
scope :active, -> () { where(completed: true) }

# if the scope does a join (or include) this must be indicated
# using the joins: option.
scope :with_recent_comments,
      -> { joins(:comments).where('comment.created_at >= ?', Time.now-1.week) },
      joins: ['comments'] # or joins: 'comments'

# the server side proc can be indicated by the server: option
# an optional client side proc can be provided to compute the scope
# locally at the client
scope :completed,
      server: -> { where(complete: true) }
      client: -> { complete } # return true if the record should be included
```

`unscoped` and `all`: These builtin scopes work just like standard ActiveRecord.

```ruby
Word.all.each { |word| LI { word.text }}
```

BTW: to save typing you can skip the `all`:  Models will respond like enumerators.

`find`: takes an id and delivers the corresponding record.

`find_by`: takes a single item hash indicating an attribute value pair to find.

`find_by_...`: i.e. `find_by_first_name` these methods will find the first record with a matching attribute.

```ruby
Word.find_by_text('hello') # short for Word.find_by(text: 'hello')
```

`limit` and `offset`: These builtin scopes behave as they do on the server:

```ruby
Word.offset(500).limit(20) # get words 500-519
```

#### Relationships and Aggregations

`belongs_to, has_many, has_one`:  These all work as on the server.  **However it is important that you fully specify both sides of the relationship.**  

```ruby
class Todo < ActiveRecord::Base
  belongs_to :assigned_to, class_name: 'User'
end

class User < ActiveRecord::Base
  has_many :todos, foreign_key: 'assigned_to_id'
end
```

Note that on the client the linkages between relationships are live and direct.  In the above example this works:

```ruby
Todo.create(assigned_to: some_user)
```

but this may not:

```ruby
Todo.create(assigned_to_id: some_user.id)
```

`composed_of`: You can create aggregate models like ActiveRecord.

Similar to the linkages in relationships, aggregate records are represented on the client as actual independent objects.

#### Defining server methods

Normally an application defined instance method will run on the client and the server:

```ruby
class User < ActiveRecord::Base
  def full_name
    "#{first_name} #{last_name}"
  end
end
```

Sometimes it is desirable to only run the method on the server.  This can be done using the `server_method` macro:

```ruby
class User < ActiveRecord::Base
  server_method :full_name, default: '' do
    "#{first_name} #{last_name}"
  end
end
```

When the method is first called on the client the default value will be returned, and there will be a reactive update when the true value is returned from the server.

To force the value to be recomputed at the server append a  `!` to the end of the name, otherwise the last value returned from the server will continue to be returned.

#### Model Information

`column_names`: returns a list of the database columns.

`columns_hash`: returns the details of the columns specification.  Note that on the server `columns_hash` returns a hash of objects specifying column information.  On the client the entire structure is just one big hash of hashes.

`abstract_class=`, `abstract_class?`, `primary_key`, `primary_key=`, `inheritance_column`, `inheritance_column=`, `model_name`:  All work as on the server.  See ActiveRecord documentation for more info.

### Instance Methods

#### Attribute and Relationship Getter and Setters

All attributes have an associated getter and setter. All relationships have a getter.  All `belongs_to` relationships also have a setter.  `has_many` relationships can be updated using the push (`<<`) operator or using the `delete` method.

```ruby
  puts my_todo.title
  my_todo.title = "neutitle"
  my_todo.comments << a_new_comment
  a_new_comment.todo == my_todo # true!
```

In addition if the attribute getter ends with a bang (!) then this will force a fetch of the attribute from the server.  This is typically not necessary if push updates are configured.

#### Saving

The `save` method works like ActiveRecord save, *except* it returns a promise that is resolved when the save completes (or fails.)

```ruby
my_todo.save(validate: false).then do |result|
  # result is a hash with {success: ..., message: , models: ....}
end
```

After a save operation completes the models will have an `errors` hash (just like on the server) with any validation problems.

During the save operation the method `saving?` will return `true`.  This can be used to instead of (or with) the promise to update the screen:

```ruby
render do
  ...
  if some_model.saving?
    ... display please wait ...
  elsif some_model.errors.any?
    ... highlight the errors ...
  else
    ... display data ...
  end
  ...
end
```

#### Destroy

Like `save` destroy returns a promise that is resolved when the destroy completes.

After the destroy completes the record's `destroyed?` method will return true.

#### Other Instance Methods

`new?` returns true if the model is new and not yet saved.

`primary_key` returns the primary key for the model

`id` returns the value of the primary key for this instance

`model_name` returns the model_name.

`revert` Undoes any unsaved changes to the instance.

`changed?` returns true if any attributes have changed (always true for a new model)

`dup` duplicate the instance.

`==` two instances are the same if it is known that they reference the same underlying table row.  

`..._changed?` (i.e. name_changed?) returns true if the specific attribute has changed.

`itself` returns the record, but will override lazy loading and force a load of at least the model's id.

### Load and Render Cycle

#### loading? and loaded?

All Ruby objects will respond to these methods.  If you want to put up a "Please Wait" message, spinner, etc, you can use the `loaded?` or `loading?` method to determine if the object represents a real loaded value or not.  Any value for which `loaded?` returns `false` (or `loading?` returns `true`) will eventually load and cause a re-render

#### Hyperstack::Model.load method

Sometimes it is necessary to insure values are loaded outside of the rendering cycle.  For this you can use the `Hyperstack::Model.load` method:

```ruby
Hyperstack::Model.load do
  x = my_model.some_attribute
  OtherModel.find(x+12).other_attribute
  # code in here can be arbitrarily complex and load
  # will re-execute it until all values are loaded
  # the final expression is passed to the promise
end.then |result|
  puts result
end
```

#### Force Loading Attributes

Normally you will simply display attributes as part of the render method, and when the values are loaded from the server the component will re-render.

Sometimes outside of the render method you may need to insure an attribute (or a server side method) is loaded before proceeding.  This is typically when you are building some kind of higher level store.  

The `load` method takes a list of attributes (symbols) and will insure these are loaded.  Load returns a promise that is resolved when the load completes, or can be passed a block that will execute when the load completes.

```ruby
before_mount do
  Todo.find(1).load(:name).then do |name|
    @name = name;
    state.loaded! true
  end
end
```

Think hard about how you are using this, as Hyperstack already acts as flux store, and is managing state for you.  It may be you are just creating a redundant store!

## Client Side Scoping

By default scopes will be recalculated on the server.  For simple scopes that do not use joins or includes no additional action needs to be taken to make scopes work with Hyperstack.  For scopes that do use joins, or if you want to offload the scoping computation from the server to the client read this section.

## ActiveRecord Scope Enhancement

When the client receives notification that a record has changed Hyperstack finds the set of currently rendered scopes that might be effected, and requests them to be updated from the server.  

On the server scopes are a useful way to structure code.  **On the client** scopes are vital as they limit the amount of data loaded, viewed, and updated in the browser.  Consider a factory floor management system that shows *job* state as work flows through the factory.  There may be millions of jobs that a production floor browser is authorized to view, but at any time there are probably only 50 being shown.  Using ActiveRecord scopes is the way Hyperstack keeps the data requested by the browser limited to a reasonable amount.  

To make scopes work efficiently on the client Hyperstack adds some features to the ActiveRecord `scope` and `default_scope` macros.  Note you must use the `scope` macro (and not class methods) for things to work with Hyperstack.

The additional features are accessed via the `:joins`, `:client`, and `:select` options.

The `:joins` option tells the Hyperstack client which models are joined with the scope.  *You must add a `:joins` option if the scope has any data base join operations in it, otherwise if a joined model changes, Hyperstack will not know to update the scope.*

The `:client` and `:select` options provide the client a way to update scopes without having to contact the server.  Unlike the `:joins` option this is an optimization and is not required for scopes to work.

```ruby
class Todo < ActiveRecord::Base

  # Standard ActiveRecord form:
  # the proc will be evaluated as normal on the server, and as needed updates
  # will be requested from the clients

  scope :active, -> () { where(completed: true) }

  # In the simple form the scope will be reevaluated if the model that is
  # being scoped changes, and if the scope is currently being used to render data.

  # If the scope joins with other data you will need to specify this by
  # passing a relationship or array of relationships to the `joins` option.

  scope :with_recent_comments,
        -> { joins(:comments).where('comment.created_at >= ?', Time.now-1.week) },
        joins: ['comments'] # or joins: 'comments'

  # Now with_recent_comments will be re-evaluated whenever a Todo record, or a Comment
  # joined with a Todo change.

  # Normally whenever Hyperstack detects that a scope may be effected by a changed
  # model, it will request the scope be re-evaluated on the server.  To offload this
  # computation to the client provide a client side scope method:

  scope :with_recent_comments,
        -> { joins(:comments).where('comment.created_at >= ?', Time.now-1.week) },
        joins: ['comments']
        client: -> { comments.detect { |comment| comment.created_at >= Time.now-1.week }

  # The client proc is executed on each candidate record, and if it returns true the record
  # will be added to the scope.

  # Instead of a client proc you can provide a select proc, which will receive the entire
  # collection which can then be filtered and sorted.

  scope :sort_by_created_at,
        -> { order('created_at DESC') }
        select: -> { sort { |a, b| b.created_at <=> a.created_at }}

  # To keep things tidy you can specify the server scope proc with the :server option

  scope :completed,
        server: -> { where(complete: true) }
        client: -> { complete }

  # The expressions in the joins array can be arbitrary sequences of relationships and
  # scopes such as 'comments.author'.  

  scope :with_managers_comments,
        server: -> { ... }
        joins: ['comments.author', 'owner']
        client: -> { comments.detect { |comment| comment.author == owner.manager }}}

  # You can also use the client, select, server, and joins option with the default_scope macro

  default_scope server: -> { where(deleted: false).order('updated_at DESC') }
                select: -> { select { |r| !r.deleted }.sort { |a, b| b <=> a } }

  # NOTE: it is highly recommend to provide a client proc with default_scopes.  Otherwise
  # every change is going to require a server interaction regardless of what other client procs
  # you provide.

end
```

#### How it works

Consider this scope on the Todo model

```ruby
scope :with_managers_comments,
      server: -> { joins(owner: :manager, comments: :author).where('managers_users.id = authors_comments.id').distinct },
      client: -> { comments.detect { |comment| comment.author == owner.manager }}
      joins: ['comments.author', 'owner']
```

The joins 'comments.author' relationship is inverted so that we have User 'has_many' Comments which 'belongs_to' Todos.

Thus we now know that whenever a User or a Comment changes this may effect our with_managers_comments scope

Likewise 'owner' becomes User 'has_many' Todos.

Lets say that a user changes teams and now has a new manager.  This means according to the relationships that the
User model will change (i.e. there will be a new manager_id in the User model) and thus all Todos belonging to that
User are subject to evaluation.

While the server side proc efficiently delivers all the objects in the scope, the client side proc just needs to incrementally update the scope.

## Configuring the Transport

Hyperstack implements push notifications (via a number of possible technologies) so changes to records on the server are dynamically pushed to all authorized clients.

The can be accomplished by configuring **one** of the push technologies below:

| Push Technology | When to choose this...        |
|---------------------------|--------------------|
| [Simple Polling](#setting-up-simple-polling) | The easiest push transport is the built-in simple poller.  This is great for demos or trying out Hyperstack but because it is constantly polling it is not suitable for production systems or any kind of real debug or test activities. |
| [Action Cable](#setting-up-action-cable) | If you are using Rails 5 this is the perfect route to go. Action Cable is a production ready transport built into Rails 5. |
| [Pusher.com](#setting-up-pusher-com) | Pusher.com is a commercial push notification service with a free basic offering. The technology works well but does require a connection to the internet at all times. |
| [Pusher Fake](#setting-up-pusher-fake) | The Pusher-Fake gem will provide a transport using the same protocol as pusher.com but you can use it to locally test an app that will be put into production using pusher.com. |

### Setting up Simple Polling

The easiest push transport is the built-in simple poller.  This is great for demos or trying out Hyperstack but because it is constantly polling it is not suitable for production systems or any kind of real debug or test activities.

Simply add this initializer:

```ruby
#config/initializers/Hyperstack.rb
Hyperstack.configuration do |config|
  config.transport = :simple_poller
  # options
  # config.opts = {
  #   seconds_between_poll: 5, # default is 0.5 you may need to increase if testing with Selenium
  #   seconds_polled_data_will_be_retained: 1.hour  # clears channel data after this time, default is 5 minutes
  # }
end
```

That's it. Hyperstack will use simple polling for the push transport.

--------------------

### Setting up Action Cable

To configure Hyperstack to use Action Cable, add this initializer:

```ruby
#config/initializers/Hyperstack.rb
Hyperstack.configuration do |config|
  config.transport = :action_cable
end
```

If you are already using ActionCable in your app that is fine, as Hyperstack will not interfere with your existing connections.

**Otherwise** go through the following steps to setup ActionCable.

Firstly, make sure the `action_cable` js file is required in your assets.

Typically `app/assets/javascripts/application.js` will finish with a `require_tree .` and this will pull in the `cable.js` file which will pull in `action_cable.js`

However at a minimum if `application.js` simply does a `require action_cable` that will be sufficient for Hyperstack.

Make sure you have a cable.yml file:

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

Set allowed request origins (optional):

**By default action cable will only allow connections from localhost:3000 in development.**  If you are going to something other than localhost:3000 you need to add something like this to your config:

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.action_cable.allowed_request_origins = ['http://localhost:3000', 'http://localhost:5000']
end
```

That's it. Hyperstack will use Action Cable as the push transport.

----------------

### Setting up Pusher.com

[Pusher.com](https://pusher.com/) provides a production ready push transport for your App.  You can combine this with [Pusher-Fake](/docs/pusher_faker_quickstart.md) for local testing as well.  You can get a free pusher account and API keys at [https://pusher.com](https://pusher.com)

First add the Pusher and Hyperstack gems to your Rails app:

add `gem 'pusher'` to your Gemfile.

Next Add the pusher js file to your application.js file:

```ruby
# app/assets/javascript/application.js
...
//= require 'Hyperstack/pusher'
//= require_tree .
```

Finally set the transport:

```ruby
# config/initializers/Hyperstack.rb
Hyperstack.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "Hyperstack"
  config.opts = {
    app_id: "2....9",
    key: "f.....g",
    secret: "1.......3"
  }
end
```

That's it. You should be all set for push notifications using Pusher.com.

-------------------------
### Setting up Pusher Fake

The [Pusher-Fake](https://github.com/tristandunn/pusher-fake) gem will provide a transport using the same protocol as pusher.com.  You can use it to locally test an app that will be put into production using pusher.com.

Firstly add the Pusher, Pusher-Fake and Hyperstack gems to your Rails app

- add `gem 'pusher'` to your Gemfile.
- add `gem 'pusher-fake'` to the development and test sections of your Gemfile.

Next add the pusher js file to your application.js file

```ruby
# app/assets/javascript/application.js
...
//= require 'Hyperstack/pusher'
//= require_tree .
```

Add this initializer to set the transport:

```ruby
# typically app/config/initializers/Hyperstack.rb
# or you can do a similar setup in your tests (see this gem's specs)
require 'pusher'
require 'pusher-fake'
# Assign any values to the Pusher app_id, key, and secret config values.
# These can be fake values or the real values for your pusher account.
Pusher.app_id = "MY_TEST_ID"      # you use the real or fake values
Pusher.key =    "MY_TEST_KEY"
Pusher.secret = "MY_TEST_SECRET"
# The next line actually starts the pusher-fake server (see the Pusher-Fake readme for details.)
# it is important this require be AFTER the above settings, as it will use these
require 'pusher-fake/support/base' # if using pusher with rspec change this to pusher-fake/support/rspec
# now copy over the credentials, and merge with PusherFake's config details
Hyperstack.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "Hyperstack"
  config.opts = {
    app_id: Pusher.app_id,
    key: Pusher.key,
    secret: Pusher.secret
  }.merge(PusherFake.configuration.web_options)
end
```

That's it. You should be all set for push notifications using Pusher Fake.

## Debugging

Sometimes you need to figure out what connections are available, or what attributes are readable etc.

Its usually all to do with your policies, but perhaps you just need a little investigation.

TODO check rr has become Hyperstack (as below)

You can bring up a console within the controller context by browsing `localhost:3000/Hyperstack/console`

**Note:  change `rr` to wherever you are mounting Hyperstack in your routes file.**

**Note: in rails 4, you will need to add the gem 'web-console' to your development section**

Within the context you have access to `session.id` and current `acting_user` which you will need, plus some helper methods to reduce typing

- Getting auto connection channels:  
`channels(session_id = session.id, user = acting_user)`  
e.g. `channels` returns all channels connecting to this session and user providing nil as the acting_user will test if connections can be made without there being a logged in user.

- Can a specific class connection be made:
`can_connect?(channel, user = acting_user)`
e.g. `can_connect? Todo`  returns true if current acting_user can connect to the Todo class. You can also provide the class name as a string.

- Can a specific instance connection be made:
`can_connect?(channel, user = acting_user)`
e.g. `can_connect? Todo.first`  returns true if current acting_user can connect to the first Todo Model. You can also provide the instance in the form 'Todo-123'

- What attributes are accessible for a Model instance:  
`viewable_attributes(instance, user = acting_user)`

- Can the attribute be viewed:  
`view_permitted?(instance, attribute, user = acting_user)`

- Can a Model be created/updated/destroyed:
`create_permitted?(instance, user = acting_user)`  
e.g. `create_permitted?(Todo.new, nil)` can anybody save a new todo?  
e.g. `destroy_permitted?(Todo.last)` can the acting_user destroy the last Todo

You can of course simulate server side changes to your Models through this console like any other console.  For example

`Todo.new.save` will broadcast the changes to the Todo Model to any authorized channels.

## Common Errors

- **No policy class**
  If you don't define a policy file, nothing will happen because nothing will get connected. By default Hyperstack will look for a `ApplicationPolicy` class.

- **Wrong version of pusher-fake**  (pusher-fake/base vs. pusher-fake/rspec) See the Pusher-Fake gem repo for details.

- Forgetting to add `require pusher` in application.js file
this results in an error like this:
  ```text
  Exception raised while rendering #<TopLevelRailsComponent:0x53e>
      ReferenceError: Pusher is not defined
  ```
  To resolve make sure you `require 'pusher'` in your application.js file if using pusher.  DO NOT require pusher from your components manifest as this will cause prerendering to fail.

- **No create/update/destroy policies**
  You must explicitly allow changes to the Models to be made by the client. If you don't you will see 500 responses from the server when you try to update. To open all access do this in your application policy: `allow_change(to: :all, on: [:create, :update, :destroy]) { true }`

- **Cannot connect to real pusher account**
  If you are trying to use a real pusher account (not pusher-fake) but see errors like this
  ```text
  pusher.self.js?body=1:62 WebSocket connection to
  'wss://127.0.0.1/app/PUSHER_API_KEY?protocol=7&client=js&version=3.0.0&flash=false'
  failed: Error in connection establishment: net::ERR_CONNECTION_REFUSED
  ```
  Check to see if you are including the pusher-fake gem.
  Hyperstack will always try to use pusher-fake if it sees the gem included.  Remove it and you should be good to go.  See [issue #5](https://github.com/hyper-react/HyperMesh/issues/5) for more details.

- **Cannot connect with ActionCable.**
  Make sure that `config.action_cable.allowed_request_origins` includes the url you use for development (including the port) and that you are using `Puma`.

- **Attributes are not being converted from strings, or do not have their default values**
Eager loading is probably turned off.  Hyperstack needs to eager load `Hyperstack/models` so it can find all the column information for all Isomorphic models.

- **When starting rails you get a message on the rails console `couldn't find file 'browser'`**
The `hyper-component` v0.10.0 gem removed the dependency on opal-browser.  You will have to add the 'opal-browser' gem to your Gemfile.

- **On page load you get a message about super class mismatch for `DummyValue`**
You are still have the old `reactive-record` gem in your Gemfile, remove it from your gemfile and your components manifest.

- **On page load you get a message about no method `session` for `nil`**
You are still referencing the old reactive-ruby or reactrb gems either directly or indirectly though a gem like reactrb-router.  Replace any gems like `reactrb-router` with `hyper-router`.  You can also just remove `reactrb`, as `hyper-model` will be included by the `hyper-model` gem.

- **You keep seeing the message `WebSocket connection to 'ws://localhost:3000/cable' failed: WebSocket is closed before the connection is established.`** every few seconds in the console.
  There are probably lots of reasons for this, but it means ActionCable can't get itself going.  One reason is that you are trying to run with Passenger instead of Puma, and trying to use `async` mode in cable.yml file.  `async` mode requires Puma.
