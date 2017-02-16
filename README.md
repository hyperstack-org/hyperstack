## HyperOperation

+ `HyperOperation` is the base class for *Operations*.  
+ An Operation orchestrates the updating of the state of your system.  
+ Operations also wrap asynchronous operations such as HTTP API requests.  
+ Operations serve the role of both Action Creators and Dispatchers described in the Flux architecture.  
+ Operations also serve as the bridge between client and server.  An operation can run on the client or the server, and can be invoked remotely.

Here is the simplest Operation:

```ruby
class Reset < HyperOperation
end
```

To 'Reset' the system you would say
```ruby
  Reset() # short for Reset.run
```

Elsewhere your HyperStores can receive the Reset *Dispatch* using the `receives` macro:

```ruby
class Cart < HyperStore::Base
  receives Reset do
    mutate.items Hash.new { |h, k| h[k] = 0 }
  end
end
```

Note that multiple stores can receive the same *Dispatch*.

### Parameters

Operations can take parameters when they are run.  Parameters are described and accessed with the same syntax as HyperReact components.

```ruby
class AddItemToCart < HyperOperation
  param :sku, type: String
  param qty: 1, type: Integer, min: 1
end

class Cart < HyperStore::Base
  receives AddItemToCart do
    mutate.items[params.sku] += params.qty
  end
end
```

In addition because HyperOperation params are *not* reactive, you can assign to them as well:
```ruby
  params.some_value = 12
```

The parameter filter types and options are taken from the [Mutations](https://github.com/cypriss/mutations) gem with the following changes:

+ In HyperOperations all params are declared with the param macro.  
+ The type *can* specified using the `type:` option.
+ Array and hash types can be shortened to `[]` and `{}`
+ Optional params either have the default value associated with the param name by having the `default` option present.
+ All other [Mutation filter options](https://github.com/cypriss/mutations/wiki/Filtering-Input) (such as `:min`) will work the same.

```ruby
  # required param (does not have a default value)
  param :sku, type: String
  # equivalent Mutation syntax
  required  { string :sku }

  # optional params (does have a default value)
  param qty: 1, min: 1
  # alternative syntax
  param :qty, default: 1, min: 1
  # equivalent Mutation syntax
  optional { integer :qty, default: 1, min: 1 }
```


### The `execute` method

Every HyperOperation has an `execute` method.  The base `execute` method dispatches (or broadcasts) the Operation parameters to all the Stores receiving the Operation's dispatches.

You can override `execute` to provide your own behavior and still call `dispatch` if you want to proceed with the dispatch.

```ruby
class Reset < HyperOperation
  def execute
    dispatch
    HTTP.post('/logout')
  end
end
```

### Asynchronous Operations

Operations are the place to put your asynchronous code:

```ruby
class AddItemToCart < HyperOperation
  def execute
    HTTP.get('/inventory/#{params.sku}/qty').then do |response|
      # don't dispatch until we know we have qty in stock
      dispatch unless params.qty > response.to_i
    end
  end
end
```

This makes it easy to keep asynchronous code out of your stores.

HyperOperations will *always* return a *Promise*.  If an Operation's execute method returns something other than a promise it will be wrapped in a resolved promise.  This lets you easily chain Operations, regardless of their internal implementation:

```ruby
class QuickCheckout < HyperOperation
  param :sku, type: String
  param qty: 1, type: Numeric, minimum: 1
  def execute
    AddItemToCart(params) do
      ValidateUserDefaultCC()
    end.then do
      Checkout()
    end
  end
end
```

You can also use `Promise#when` if you don't care about the order of Operations

```ruby
class DoABunchOStuff < HyperOperation
  def execute
    Promise.when(SomeOperation.run, SomeOtherOperation.run).then do
      dispatch
    end
  end
end
```

### Handling Failures

Because Operations always return a promise, you can use the `fail` method on the result to detect failures.

```ruby
QuickCheckout(sku: selected_item, qty: selected_qty)
.then do
  # show confirmation
end
.fail do |exception|
  # whatever exception was raised is passed to the fail block
end
```
Failures to validate params result in `Hyperloop::ValidationException` which contains a [Mutations error object](https://github.com/cypriss/mutations#what-about-validation-errors).
```ruby
MyOperation.run.fail do |e|
  if e.is_a? Hyperloop::ValidationException
    e.errors.symbolic # hash: each key is a parameter that failed validation, value is a symbol representing the reason
    e.errors.message # same as symbolic but message is in English
    e.errors.message_list # array of messages where failed parameter is combined with the message
  end
end
```

### Dispatch Syntax

You can dispatch to an Operation by using ...
+ the Operation class name as a method:  
  ```
  MyOperation()
  ```
+ the `run` method:  
  ```
  MyOperation.run
  ```
+ the `then` method, which will dispatch the operation and attach a promise handler:  
  ```
  MyOperation.then { alert 'operation completed' }
  ```


### The `HyperOperation::Server` Class

HyperOperations can run on the client or the server.  Some Operations like `ValidateUserDefaultCC` probably needs to check information server side, and perhaps make secure API calls to our credit card processor which again can only be done from the server.  Rather than build an API and controller to "validate the user credentials" you simply specify that the operation must run on the server by using the `HyperOperation::Server` class.

```ruby
class ValidateUserCredentials < HyperOperation::Server
  def validate
    add_error(:acting_user, :invalid_default_cc, "No valid default credit card") unless params.acting_user.has_default_cc?
  end
end
```

`HyperOperation::Server` is a subclass of `HyperOperation` that will always run on the server even if invoked on the client.  Server Operations always take an additional parameter `param :acting_user` that is predefined for you, and will be initialized with whatever the current value of your ApplicationController's `acting_user` method is.   By default `acting_user` must not be nil, but you can override this by providing your own declaration: `param :acting_user, nils: true`.

As shown above you can also define a `validate` method to further verify that the acting_user (with perhaps other parameters) is allowed to perform the operation.  In the above case that is the only purpose of Operation.

### Dispatching From Server Operations

You can also broadcast the dispatch from Server Operations to all authorized clients:

```ruby
class Announcement < HyperOperation::Server
  param :message
  param :duration
  # dispatch to the Application channel
  regulate_dispatch Application
end

class CurrentAnnouncements < HyperStore::Base
  state_reader all: [], scope: :class
  receives Announcement do
    mutate.all << params.message
    after(params.duration) { delete params.message } if params.duration
  end
  def self.delete(message)
    mutate.all.delete message
  end
end
```

The `regulate_dispatch` policy takes a list of classes, representing *Channels.*  The Operation will be dispatched to all clients connected on those Channels.   Alternatively `regulate_dispatch` can take a block, a symbol (indicating a method to call) or a proc.  The block, proc or method should return a single Channel, or an array of Channels, which the Operation will be dispatched to.   The dispatch regulation has access to the params object.  For example we can add an optional `to` param to our Operation, and use this to select which Channel we will broadcast to.

```ruby
class Announcement < HyperOperation
  param :message
  param :duration
  param to: nil, type: User
  # downlink only to the Users channel if specified
  regulate_dispatch do
    params.to || Application
  end
end
```

### Regulating Dispatches in Policy Classes

```ruby
class Announcement < HyperOperation::Server
  # all clients will have a Announcement Channel which will receive all dispatches from the Annoucement Operation
  always_allow_connection
end
# regulations can be specified in the class or in a separate policy file
class AnnouncementPolicy
  always_allow_connection
end

class UserPolicy
  regulate_instance_connection { self }
  regulate_

```

    class AdminUserPolicy
      # channel
      regulate_dispatches_from(Operation1, Operation2, Operation3) &block
        Operation1.regulate_dispatch { AdminUser if &block.call }
      always_dispatch_from(....)
        Operation1.regulate_dispatch(AdminUser)
    end

    class Operation1Policy
      always_allow_connection
        always_allow_connection + Operation1.regulate_dispatch(Operation1)
      regulate_class_connection &block # now we have a channel connected to the operation ... that is cool
        regulate_class_connection &block + Operation1.regulate_dispatch(Operation1)
      regulate_dispatch(list of channel classes) { returns 1 or more channels }
    end


regulate_dispatch <- applied directly to an Operation
regulate_dispatches_from
always_dispatch_from

+ the application, or some function within the application
+ or some class which is *authenticated* like a User or Administrator,
+ instances of those classes,
+ or instances of related classes.


### Serialization

If you need to control serialization and deserialization you can define the following *class* methods:

```ruby
def self.serialize_params(hash)
  # receives param_name -> value pairs
  # return an object ready for to_json
  # default is just return the input hash
end

def self.deserialize_params(object)
  # recieves whatever was returned from serialize_to_server
  # (param_name => value pairs by default)
  # must return a hash of param_name => value pairs
  # by default this returns object
end

def self.serialize_response(object)
  # receives the object ready for to_json
  # by default this returns object
end

def self.deserialize_response(object)
  # receives whatever was returned from serialize_response
  # by default this returns object
end

def self.serialize_dispatch(hash)
  # input is always key - value pairs
  # return an object ready for to_json
  # default is just return the input hash
end

def self.deserialize_dispatch(object)
  # recieves whatever was returned from serialize_to_server
  # (param_name => value pairs by default)
  # must return a hash of param_name => value pairs
  # by default this returns object
end
```



The value of the first parameter (`serializing` above) is a symbol with additional methods corresponding to each of the parameter names (i.e. `message?`, `duration?` and `to?`) plus `exception?` and `result?`

Make sure to call `super` unless you are serializing/deserializing all values.

### Isomorphic Operations

If an Operation has no uplink or downlink regulations it will run on the same place as it was dispatched from.  This can be handy if you have an Operation that needs to run on both the server and the client.  For example an Operation that calculates the customers discount, will want to run on the client so the user gets immediate feedback, and then will be run again on the server when the order is submitted as a double check.

### Dispatching With New Parameters

The `dispatch` method sends the `params` object on the receivers.  Sometimes it's useful for the to add additional outbound params before dispatching.  Additional params can be declared using the `outbound` macro.  They can then be added to the dispatch directly:

```ruby
class AddItemToCart < HyperOperation
  param :sku, type: String
  param qty: 1, type: Integer, minimum: 1
  outbound :available

  def execute
    HTTP.get('/inventory/#{params.sku}/qty').then do |response|
      dispatch available: response.to_i unless params.qty > response.to_i
    end
  end
end
```

Or you can assign them before the dispatch:

```ruby
  params.available = response.to_i
```

You can also use the same mechanisms to update incoming params as well:
```ruby
class AddItemToCart < HyperOperation
  param :sku, type: String
  param qty: 1, type: Integer, minimum: 1
  outbound :requested

  def execute
    HTTP.get('/inventory/#{params.sku}/qty').then do |response|
      dispatch requested: params.qty, qty: response.to_i
    end
  end
end  
```
Or if you prefer a more procedural approach:
```ruby
  def execute
    params.requested = params.qty
    HTTP.get('/inventory/#{params.sku}/qty').then do |response|
      params.qty = response.to_i
      dispatch
    end
  end
```

### Instance Verses Class Execution Context

Normally the execute method is declared, and runs as an instance method.  An instance of the Operation is created, runs and is thrown away.  

Sometimes it's useful to declare `execute` as a class method.  This is useful especially for caching values, between calls to the Operation.  Note that the primary use should be in interfacing to outside APIs.  Don't hide your application state inside an Operation - Move it to a Store.

```ruby
class GetRandomGithubUser < HyperOperation
  def self.execute
    return @users.delete_at(rand(@users.length)) unless @users.blank?
    @promise = HTTP.get("https://api.github.com/users?since=#{rand(500)}").then do |response|
      @users = response.json.collect do |user|
        { name: user[:login], website: user[:html_url], avatar: user[:avatar_url] }
      end
    end if @promise.nil? || @promise.resolved?
    @promise.then { execute }
  end
end
```

Before the class `execute` method is called an instance of the operation is created to hold the current parameter values, dispatcher, etc.  If the class `execute` method accepts a parameter, this object will be sent in, and can be used.

```ruby
class Interesting < HyperOperation
  param :increment
  param :multiply
  outbound :result
  outbound :total
  def self.execute(op)
    @total ||= 0
    @total += (op.params.result = op.params.increment * op.params.multiply)
    op.dispatch {total: @total}
  end
end
```

### The `Hyperloop::Boot` Operation

Hyperloop includes one predefined Operation, `Hyperloop::Boot`, that runs at system initialization.  Stores can receive Hyperloop::Boot to initialize their state.  To reset the state of the application you can simply execute `Hyperloop::Boot`

### Flux and Operations

Hyperloop is a merger of the concepts of the Flux pattern, the [Mutation Gem](https://github.com/cypriss/mutations), and Trailblazer Operations.

We chose the name `Operation` rather than `Action` or `Mutation` because we feel it best captures all the capabilities of a HyperOperation.  Nevertheless HyperOperations are fully compatible with the Flux Pattern.

| Flux | HyperLoop |
|-----| --------- |
| Action | HyperOperation subclass |
| ActionCreator | `HyperOperation#execute` method |
| Action Data | HyperOperation parameters |
| Dispatcher | `HyperOperation#dispatch` method
| Registering a Store | `Store.receives` |

In addition Operations have the following capabilities:

+ Can easily be chained because they always return promises.
+ Clearly declare both their parameters, and what they will dispatch.
+ Parameters can be validated and type checked.
+ Can run remotely on the server.
+ Can be dispatched from the server to all authorized clients.
+ Can hold their own state data when appropriate.
