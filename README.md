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
  param qty: 1, type: Integer, minimum: 1

  step { AddItemToCart(params) }
  step ValidateUserDefaultCC
  step Checkout

  def execute
    AddItemToCart(params)
    .then do
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

### The `validate` method

An Operation can also have a `validate` method which will be called before the `execute` method.  This is a handy place to put any additional validations.  In the validate method you can add validation type messages using the `add_error` method, and these will be passed along like any other param validation failures.

```ruby
class UpdateProfile < HyperOperation
  param :first_name, type: String  
  param :last_name, type: String
  param :password, type: String, nils: true
  param :password_confirmation, type: String, nils: true

  def validate
    add_error(
      :password_confirmation,
      :doesnt_match,
      "Your new password and confirmation do not match"
    ) unless params.password == params.confirmation
  end
  ...
end
```
If the validate method returns a promise, then execution will wait until the promise resolves.  If the promise fails, then the whole operation will fail.

You can also raise an exception directly in validate if appropriate.

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
    e.errors.symbolic     # hash: each key is a parameter that failed validation,
                          # value is a symbol representing the reason
    e.errors.message      # same as symbolic but message is in English
    e.errors.message_list # array of messages where failed parameter is
                          # combined with the message
  end
end
```

### Dispatch Syntax

You can dispatch to an Operation by using ...
+ the Operation class name as a method:  
```ruby
MyOperation()
```
+ the `run` method:  
```ruby
MyOperation.run
```
+ the `then` and `fail` methods, which will dispatch the operation and attach a promise handler:  
```ruby
MyOperation.then { alert 'operation completed' }
```


### The `Hyperloop::ServerOp` class

Operations will run on the client or the server.  Some Operations like `ValidateUserDefaultCC` probably need to check information server side, and perhaps make secure API calls to our credit card processor which again can only be done from the server.  Rather than build an API and controller to "validate the user credentials" you simply specify that the operation must run on the server by using the `Hyperloop::ServerOp` class.

```ruby
class ValidateUserCredentials < Hyperloop::ServerOp
  param :acting_user
  def validate
    add_error(
      :acting_user, :no_valid_default_cc,
      "No valid default credit card"
    ) unless params.acting_user.has_default_cc?
  end
  # no execute method needed in this case...
end
```

A Server Operation will always run on the server even if invoked on the client.  When invoked from the client Server Operations will receive the `acting_user` param with the current value of your ApplicationController's `acting_user` method returns.   Typically the `acting_user` method will return either some User model, or nil (if there is no logged in user.)  Its up to you to define how `acting_user` is computed, but this is easily done with any of the proper authentication gems.  Note that unless you explicitly add `nils: true` to the param declaration, nil will not be accepted.

As shown above you can also define a `validate` method to further verify that the acting user (with perhaps other parameters) is allowed to perform the operation.  In the above case that is the only purpose of Operation.   A typical use would be to make sure the current acting user has the correct role to perform the operation:

```ruby
  ...
  def validate
    raise Hyperloop::AccessViolation unless params.acting_user.admin?
  end
  ...
```

You can bake this kind logic into a class:

```ruby
class AdminOnlyOp < Hyperloop::ServerOp
  param :acting_user
  def validate
    raise Hyperloop::AccessViolation unless params.acting_user.admin?
  end
end

class DeleteUser < AdminOnlyOp
  param :user
  def validate
    add_error(
      :user, :cant_delete_user
      "Can't delete yourself, or the last admin user"
    ) if params.user == params.acting_user || (params.user.admin? && AdminUsers.count == 1)
  end
end
```

Note that there is no need to call `super`, as Hyperloop will chain the validate methods together for you.

Because Operations always return a promise, there is no code changed needed on the client to handle a Server Operation. A Server Operation will return a promise that will be resolved (or rejected) when the Operation completes (or fails) on the server.  

### Dispatching From Server Operations

You can also broadcast the dispatch from Server Operations to all authorized clients:

```ruby
class Announcement < Hyperloop::ServerOp
  # no acting_user because we don't want clients to invoke the Operation
  param :message
  param :duration, type: Float, nils: true
  # dispatch to the Application channel
  dispatch_to Application
end

class CurrentAnnouncements < Hyperloop::Store
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

#### Channels

As seen above broadcasting is done over a *Channel*.  Any ruby class (including Operations) can be used *class channel*.  Any Ruby class that responds to the `id` method can be used as an *instance channel.*  

For example the `User` active record model could be a used as channel to broadcast to *all* users.  Each user instance could also be a separate instance channel that would be used to broadcast to that user.

The purpose of having channels is to restrict what gets broadcast to who, therefore typically channels represent *connections* to

+ the application (represented by the `Hyperloop::Application` class), or some function within the application (like an Operation)
+ or some class which is *authenticated* like a User or Administrator,
+ instances of those classes,
+ or instances of classes in some relationship like a `team` that a `user` belongs to.

You create a channel by including the `Hyperloop::PolicyMethods` module.

This gives you three class methods: `regulate_class_connection` `always_allow_connection` and `regulate_instance_connections`.  For example:

```ruby
class User < ActiveRecord::Base
  include Hyperloop::PolicyMethods
  regulate_class_connection { self }  
  regulate_instance_connection { self }
end
```

will attach the current acting user to the  `User` channel (which is shared with all users) and to that user's private channel.

Both blocks have self == to the current acting user, but the return value has a different meaning.  If regulate_class_connection returns any truthy value, then the class level connection will be made on behalf of the acting user.  On the other hand `regulate_instance_connection` returns an array (possibly nested) or Active Record relationship and an instance connection is made with each object.  So for example you could add:

```ruby
class User < ActiveRecord::Base
  # assume has_many :chat_rooms
  regulate_instance_connection { chat_rooms }
  # we will connect to all the chat rooms we are members of
end
```

Now if we want to broadcast to all users our operation would have

```ruby
  dispatch_to User # dispatch to the User class channel
```

or to send an announcement to specific user

```ruby
class PrivateAnnouncement < Hyperloop::ServerOp
  param :receiver
  param :message
  # dispatch_to can take a block if we need to dynamically
  # compute the channels
  dispatch_to { params.receiver }
end
...
# somewhere else in the server
PrivateAnnouncement(receiver: User.find_by_login(login), message: 'log off now!')
```  

Usually some other client would be sending the message so the operation could look like this:

```ruby
class PrivateAnnouncement < Hyperloop::ServerOp
  param :acting_user
  param :receiver
  param :message
  def validate
    raise Hyperloop::AccessViolation unless params.acting_user.admin?
    params.receiver = User.find_by_login(receiver)
  end
  dispatch_to { params.receiver }
end
```

Now on the client we can say:

```ruby
  PrivateAnnouncement(receiver: login_name, message: 'log off now!').fail do
    alert('message could not be sent')
  end
```

and elsewhere in the client code we would have a component like this:

```ruby
class Alerts < Hyperloop::Component
  before_mount do
    mutate.alert_messages = []
    receives PrivateAnnouncement { |params| mutate.alert_messages << params.message }
  end
  render(DIV, class: :alert_messages) do
    UL do
      state.alert_messages.each do |message|
        LI do
          SPAN { message }
          BUTTON { 'dismiss' }.on(:click) { mutate.alert_messages.delete(message) }
        end
      end
    end
  end
end
```

This will
+ associates a channel with each logged in user
+ invoke the PrivateAnnouncement Operation on the server (remotely from the client)
+ validate that there is a logged in user at that client
+ validate that we have a non-nil, non-blank receiver and message
+ validate that the acting_user is an admin
+ lookup the receiver in the database under their login name
+ dispatch the parameters back to any clients where the receiver is logged in
+ those clients will update their alert_messages state and
+ display the message


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

  on_dispatch do |params|
    dispatch
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
  regulate_dispatch { params.acting_user }

```

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

Unless the Operation is a Server Operation it will run where it was invoked.   This can be handy if you have an Operation that needs to run on both the server and the client.  For example an Operation that calculates the customers discount, will want to run on the client so the user gets immediate feedback, and then will be run again on the server when the order is submitted as a double check.

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

Hyperloop includes one predefined Operation, `Hyperloop::Boot`, that runs at system initialization.  Stores can receive `Hyperloop::Boot` to initialize their state.  To reset the state of the application you can simply execute `Hyperloop::Boot`

### Flux and Operations

Hyperloop is a merger of the concepts of the Flux pattern, the [Mutation Gem](https://github.com/cypriss/mutations), and Trailblazer Operations.

We chose the name `Operation` rather than `Action` or `Mutation` because we feel it best captures all the capabilities of a `Hyperloop::Operation`.  Nevertheless Operations are fully compatible with the Flux Pattern.

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
