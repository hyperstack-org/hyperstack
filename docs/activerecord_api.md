## ActiveRecord API

HyperMesh uses a subset of the standard ActiveRecord API to give your client side HyperReact components access to your server side models.  As much as possible HyperMesh follows the syntax as semantics of ActiveRecord.  

### Interfacing to React

HyperMesh integrates with React to deliver your model data to the client without you having to create extra APIs or specialized controllers.  The key idea of React is that when state (or params) change, the portions of the display effected by this data will be updated.

HyperMesh automatically creates react state objects that will be updated as server side data is loaded, or changes.  When these states change the associated parts of the display will be updated.

A brief overview of how this works will help you understand the how HyperMesh gets the job done.

#### Rendering Cycle

On the UI you will be reading models in order to display data.

If during the rendering of the display the model data is not yet loaded, placeholder values (the default values from the `columns_hash`) will be returned by HyperMesh.  

HyperMesh then keeps track of where these placeholders (or `DummyValue`s) are displayed, and when they do get loaded, those parts of the display will re-render.

If later the data changes (either due to local user actions, or receiving push updates) then again any parts of the display that were dependent on the current values will be re-rendered.

You normally do not have to be aware of this.  Just access your models using the normal scopes and finders, then compute values and display attributes as you would on the server.  Initially the display will show the placeholder values and then will be replaced with the real values.

#### Prerendering

During server-side pre-rendering, HyperMesh as direct access to the server so on initial page load all the values will be loaded and present.  

#### Lazy Loading

HyperMesh lazy loads values, and does not load any thing until an explicit displayable value is requested.  For example `Todo.all` will have no action, but `Todo.all.pluck[:title]` will return an array of titles.

At the end of the rendering cycle the set of all values requested will be merged into a tree structure and sent to the server, returning the minimum amount of data needed.

#### Load Cycle Methods

There are a number of methods that allow you to interact with this load cycle when needed.  These are documented [below](#other-methods-for-interacting-with-the-load-and-render-cycle).

### Class Methods

#### New and Create

`new`: Takes a hash of attributes and initializes a new unsaved record.  The values of any attributes not specified in the hash will be taken from the models default values specified in the `columns_hash`.

If `new` is passed a native javascript object it will be treated as a hash and converted accordingly.

`create`: Short hand for `new(...).save`.  See the `save` instance method for details on how saving is done.

#### Scoping and Finding

`scope` and `default_scope`:  HyperMesh adds four new options to these methods: `joins`, `client`, `select` and `server`.  The `joins` option provides information on how the scope will be joined with other models.  The `client` and `select` options allow scoping to be done on the client side to offload this from the server, and the `server` option is there just for symmetry with the other options.  See the [Client Side Scoping](/docs/client_side_scoping.md) page for more details.

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

BTW: to save typing you can skip the `all`:  Models will respond like enumerators

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

`belongs_to, has_many, has_one`:  These all work as on the server.  However it is important that you fully specify both sides of the relationship.  

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

All attributes have an associated getter and setter. All relationships have a getter.  All belongs_to relationships also have a setter.  `has_many` relationships can be updated using the push (`<<`) operator or using the `delete` method.

```ruby
  puts my_todo.name
  my_todo.name = "neuname"
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

After saving the models will have an `errors` hash (just like on the server) with any validation problems.

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

`==` two instances are the same if they reference the same underlying table row.  

`..._changed?` (i.e. name_changed?) returns true if the specific attribute has changed.

`itself` returns the record, but will override lazy loading and force a load of at least the model's id.

### Other Methods for Interacting with the Load and Render Cycle

#### `loading?` and `loaded?`

All Ruby objects will respond to these methods.  If you want to put up a "Please Wait" message, spinner, etc, you can use the `loaded?` or `loading?` method to determine if the object represents a real loaded value or not.  Any value for which `loaded?` returns `false` (or `loading?` returns true) will eventually load and cause a re-render

#### The `HyperMesh.load` Method

Sometimes it is necessary to insure values are loaded outside of the rendering cycle.  For this you can use the `HyperMesh.load` method:

```ruby
HyperMesh.load do
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

The `load` takes a list of attributes (symbols) and will insure these are loaded.  Load returns a promise that is resolved when the load completes, or can be passed a block that will execute when the load completes.

```ruby
before_mount do
  Todo.find(1).load(:name).then do |name|
    @name = name;
    state.loaded! true
  end
end
```

Think hard about how you are using this, as HyperMesh already acts as flux store, and is managing state for you.  It may be you are just creating a redundant store!
