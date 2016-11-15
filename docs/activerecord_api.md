## ActiveRecord API

HyperMesh uses a subset of the standard ActiveRecord API to give your client side HyperReact components access to your server side models.

### Class Methods

`scope` and `default_scope`:  HyperMesh adds four new options to these methods: `joins`, `client`, `select` and `server`.  The `joins` option provides information on how the scope will be joined with other models.  The `client` and `select` options allow scoping to be done on the client side to offload this from the server, and the `server` option is there just for symmetry with the othe options.  See the [Client Side Scoping](/docs/client_side_scoping.md) page for more details.

```ruby
# the scope proc is executed on the server
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
      client: -> { complete }
```

`unscoped` and `all`: These builtin scopes work just like standard ActiveRecord.

```ruby
Word.all.each { |word| LI { word.text }}
```

`belongs_to, has_many, has_one`:  These all work as on the server.  However it is important that you fully specify both sides of the relationship.  This is not always necessary on the server because ActiveRecord uses the table schema to work things out.

```ruby
class Todo < ActiveRecord::Base
  belongs_to :assigned_to, class_name: 'User'
end

class User < ActiveRecord::Base
  has_many :todos, foreign_key: 'assigned_to_id'
end
```

`composed_of`: You can create aggregate models like ActiveRecord.

`column_names`: returns a list of the database columns.

`columns_hash`: returns the details of the columns specification.  Note that on the server `columns_hash` returns a hash of objects specifying column information.  On the client the entire structure is just one big hash of hashes.

`abstract_class=`, `abstract_class?`, `primary_key`, `primary_key=`, `inheritance_column`, `inheritance_column=`, `model_name`: All work as on the server.  See ActiveRecord documentation for more info.

`new`: Takes a hash of attributes and initializes a new unsaved record.  The values of any attributes not specified in the hash will be taken from the models default values specified in the `columns_hash`.

If new is passed a native javascript object it will be treated as a hash and converted accordingly.

`create`: Short hand for `new(...).save`.  See the `save` instance method for details on how saving is done.

`limit` and `offset`: These builtin scopes behave as they do on the server:

```ruby
Word.offset(500).limit(20) # get words 500-519
```

`find`: takes an id and returns the corresponding record.

`find_by`: takes single item hash indicating an attribute value pair to find.

`find_by_...`: i.e. `find_by_first_name` these will find the first record with a matching attribute.

```ruby
Word.find_by_text('hello') # short for Word.find_by(text: 'hello')
```
