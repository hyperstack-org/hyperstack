## ActiveRecord Scope Enhancement (DO NOT USE API SUBJECT TO CHANGE AT ANY TIME)

When the client receives notification that a record has changed Synchromesh finds the set of currently rendered scopes that might be effected, and requests them to be updated from the server.  

To give you control over this process Synchromesh adds some features to the ActiveRecord scope macro.  Note you must use the `scope` macro (and not class methods) for things to work with Synchromesh.

Synchromesh `scope` adds an optional third parameter and an optional block:

```ruby
class Todo < ActiveRecord::Base

  # Standard ActiveRecord form:
  # the proc will be evaluated as normal on the server, and as needed updates
  # will be requested from the clients
  scope :active, -> () { where(completed: true) }
  # In the simple form the scope will be reevaluated if the model that is
  # being scoped changes, and if the scope is currently being used to render data.

  # If the scope joins with other data you will need to specify this by
  # passing a single model or array of the joined models to the `joins` option.
  scope :with_recent_comments,
        -> () { joins(:comments).where('created_at >= ?', Time.now-1.week) },
        joins: [Comments] # or joins: Comments
  # Now with_recent_comments will be re-evaluated whenever Comments or Todo records
  # change.  The array can be the second or third parameter.

  # It is possible to optimize when the scope is re-evaluated by providing a proc
  # to the `sync` option.  If the proc returns true then the scope will be reevaluated.
  scope :active, -> () { where(completed: true) }, sync: -> (record) do
    (record.completed.nil? && record.destroyed?) || record.previous_changes[:completed]
  end
  # In other words only reevaluate if an "uncompleted" record was destroyed or if
  # the completed attribute has changed.  Note the use of the ActiveRecord
  # previous_changes method.  Also note that the attributes in record are "after"
  # changes are made unless the record is destroyed.

  # For heavily used scopes you can even update the scope manually on the client
  # using the second parameter passed to the sync proc:
  scope :active, -> () { where(completed: true) }, sync: -> (record, collection) do
    if record.completed
      collection.delete(record)
    else
      collection << record
    end
    nil # return nil so we don't resync the scope from the server
  end

  # The 'joins-array' applies to the sync proc as well.  in other words if no joins
  # array is provided the block will only be called if records for scoped model
  # change.  If a joins array is provided, then the additional models will be added
  # to the join filter.  
  scope :scope1, -> () {...}, joins: [AnotherModel], sync: -> (record) do
    # record will be either a Todo, or AnotherModel
  end

  # The keyword :all means join all models:
  scope :scope2, -> () { ... }, joins: :all, sync: -> (record) do
    # any change to any model will be passed to the sync proc
  end

  # Instead of a proc you can set sync to false
  scope :never_synced_scope, -> () { ... }, sync: false

end
```

**Limitation**  currently you can chain scopes synced on the client.  This limitation will be lifted soon!
