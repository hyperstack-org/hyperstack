# HyperOperations

# Work in progress - ALPHA (docs and code)

Operations are the engine rooms of Hyperstack; they orchestrate the interactions between Components, external services, Models, and Stores. Operations provide a tidy place to keep your business logic.

Operations receive parameters and execute a series of steps. They have a simple structure which is not dissimilar to a Component:

```ruby
class SimpleOperation < Hyperstack::Operation
  param :anything
  step { do_something }
end

#to invoke from anywhere
SimpleOperation.run(anything: :something)
.then { success }
.fail { fail }
```

Hyperstack's Isomorphic Operations span the client and server divide automagically. Operations can run on the client, the server, and traverse between the two.

This goal of this documentation is to outline Operations classes and provides enough information and examples to show how to implement Operations in an application.

### Operations have three core functions

Operations are packaged as one neat package but perform three different functions:

1. Operations encapsulate business logic into a series of steps
2. Operations can dispatch messages (either on the client or between the client and server)
3. ServerOps can be used to replace boiler-plate APIs through a bi-directional RPC mechanism

**Important to understand:** There is no requirement to use all three functions. Use only the functionality your application requires.

## Operations encapsulate business logic

In a traditional MVC architecture, the business logic ends up either in Controllers, Models, Views or some other secondary construct such as service objects, helpers, or concerns. In Hyperstack,  Operations are first class objects who's job is to mutate state in the Stores, Models, and Components. Operations are discreet logic, which is of course, testable and maintainable.

An Operation does the following things:

1. receives incoming parameters, and does basic validations  
2. performs any further validations  
3. executes the operation  
4. dispatches to any listeners  
5. returns the value of the execution (step 3)

These are defined by series of class methods described below.

### Operation Structure

`Hyperstack::Operation` is the base class for an *Operation*

As an example, here is an Operation which ensures that the Model being saved always has the current `created_by` and `updated_by` `Member`.

```ruby
class SaveWithUpdatingMemberOp < Hyperstack::Operation
  param :model
  step { params.model.created_by = Member.current if params.model.new? }
  step { params.model.updated_by = Member.current }
  step { model.save.then { } }
end
```
This Operation is run from anywhere in the client or server code:

```ruby
SaveWithUpdatingMemberOp.run(model: MyModel)
```

Operations always return Promises, and those Promises can be chained together. See the section on Promises later in this documentation for details on how Promises work.

Operations can invoke other Operations so you can chain a sequence of `steps` and Promises which proceed unless the previous `step` fails:

```ruby
class InvoiceOpertion < Hyperstack::Operation
  param :order, type: Order
  param :customer, type: Customer

  step { CheckInventoryOp.run(order: params.order) }
  step { BillCustomerOp.run(order: params.order, customer: params.customer) }
  step { DispatchOrderOp.run(order: params.order, customer: params.customer) }
end
```

This approach allows you to build readable and testable workflows in your application.

### Running Operations

To run an Operation:

+ use the `run` method:  

```ruby
MyOperation.run
```

+ passing params:

```ruby
MyOperation.run(params)
```

+ the `then` and `fail` methods, which will dispatch the operation and attach a promise handler:  

```ruby
MyOperation.run(params)
.then { do_the_next_thing }
.fail { puts 'failed' }
```

### Parameters

Operations can take parameters when they are run.  Parameters are described and accessed with the same syntax as Hyperstack Components.

The parameter filter types and options are taken from the [Mutations](https://github.com/cypriss/mutations) gem with the following changes:

+ In Hyperstack::Operations all params are declared with the param macro  
+ The type *can* be specified using the `type:` option
+ Array and hash types can be shortened to `[]` and `{}`
+ Optional params either have the default value associated with the param name or by having the `default` option present
+ All other [Mutation filter options](https://github.com/cypriss/mutations/wiki/Filtering-Input) (such as `:min`) will work the same

```ruby
  # required param (does not have a default value)
  param :sku, type: String
  # equivalent Mutation syntax
  # required  { string :sku }

  # optional params (does have a default value)
  param qty: 1, min: 1
  # alternative syntax
  param :qty, default: 1, min: 1
  # equivalent Mutation syntax
  # optional { integer :qty, default: 1, min: 1 }
```

All incoming params are validated against the param declarations, and any errors are posted to the `@errors` instance variable.  Extra params are ignored, but missing params unless they have a default value will cause a validation error.

### Defining Execution Steps

Operations may define a sequence of steps to be executed when the operation is run, using the `step`, `failed` and `async` callback macros.

```ruby
class Reset < Hyperstack::Operation
  step { HTTP.post('/logout') }
end
```

+ `step`: runs a callback - each step is run in order.
+ `failed`: runs a callback if a previous `step` or validation has failed.
+ `async`: will be explained below.

```ruby
  step    {  } # do something
  step    {  } # do something else once above step is done
  failed  {  } # do this if anything above has failed
  step    {  } # do a third thing, unless we are on the failed track
  failed  {  } # do this if anything above has failed
```

Together `step` and `failed` form two *railway tracks*.  Initially, execution proceeds down the success track until something goes wrong; then execution switches to the failure track starting at the next `failed` statement.  Once on the failed track execution continues performing each `failed` callback and skipping any `step` callbacks.

Failure occurs when either an exception is raised, or a Promise fails (more on this in the next section.) The Ruby `fail` keyword can be used as a simple way to switch to the failed track.

Both `step` and `failed` can receive any results delivered by the previous step.   If the last step raised an exception (outside a Promise), the failure track would receive the exception object.

The callback may be provided to `step` and `failed` either as a block, a symbol (which will name a method), a proc, a lambda, or an Operation.

```ruby
  step { puts 'hello' }
  step :say_hello
  step -> () { puts 'hello' }
  step Proc.new { puts 'hello' }
  step SayHello # your params will be passed along to SayHello
```

FYI: You can also use the Ruby `next` keyword as expected to leave the current step and move to the next one.

### Promises and Operations

Within the browser, the code does not wait for asynchronous methods (such as HTTP requests or timers) to complete.  Operations use Opal's [Promise library](http://opalrb.org/docs/api/v0.10.3/stdlib/Promise.html) to deal with these situations cleanly.  A Promise is an object that has three states:  It is either still pending, or has been rejected (i.e. failed), or has been successfully resolved.  A Promise can have callbacks attached to either the failed or resolved state, and these callbacks will be executed once the Promise is resolved or rejected.

If a `step` or `failed` callback returns a pending Promise then the execution of the operation is suspended, and the Operation will return the Promise to the caller.  If there is more track ahead, then execution will resume at the next step when the Promise is resolved.  Likewise, if the pending Promise is rejected execution will resume on the next `failed` callback.  Because of the way Promises work, the operation steps will all be completed before the resolved state is passed along to the caller so that everything will execute in its original order.

Likewise, the Operation's dispatch occurs when the Promise resolves as well.

The `async` method can be used to override the waiting behavior.  If a `step` returns a Promise, and there is an `async` callback further down the track, execution will immediately pick up at the `async`.  Any steps in between will still be run when the Promise resolves, but their results will not be passed outside of the operation.

These features make it easy to organize, understand and compose asynchronous code:

```ruby
class AddItemToCart < Hyperstack::Operation
  step { HTTP.get('/inventory/#{params.sku}/qty') }
  # previous step returned a Promise so next step
  # will execute when that Promise resolves
  step { |response| fail if params.qty > response.to_i }
  # once we are sure we have inventory we will dispatch
  # to any listening stores.
end
```

Operations will *always* return a *Promise*.  If an Operation has no steps that return a Promise the value of the last step will be wrapped in a resolved Promise.  Operations can be easily changed regardless of their internal implementation:

```ruby
class QuickCheckout < Hyperstack::Operation
  param :sku, type: String
  param qty: 1, type: Integer, minimum: 1

  step { AddItemToCart.run(params) }
  step ValidateUserDefaultCC
  step Checkout
end
```

You can also use `Promise#when` if you don't care about the order of Operations

```ruby
class DoABunchOStuff < Hyperstack::Operation
  step { Promise.when(SomeOperation.run, SomeOtherOperation.run) }
  # dispatch when both operations complete
end
```

### Early Exits

Any `step` or `failed` callback, can have an immediate exit from the Operation using the `abort!` and `succeed!` methods.  The `abort!` method returns a failed Promise with any supplied parameters.  The `succeed!` method does an immediate dispatch and returns a resolved Promise with any supplied parameters.  If `succeed!` is used in a `failed` callback, it will override the failed status of the Operation.  This is especially useful if you want to dispatch in spite of failures:

```ruby
class Pointless < Hyperstack::Operation
  step { fail }       # go to failure track
  failed { succeed! } # dispatch and exit
end
```

### Validation

An Operation can also have some `validate` callbacks which will run before the first step.  This is a handy place to put any additional validations.  In the validate method you can add validation type messages using the `add_error` method, and these will be passed along like any other param validation failures.

```ruby
class UpdateProfile < Hyperstack::Operation
  param :first_name, type: String  
  param :last_name, type: String
  param :password, type: String, nils: true
  param :password_confirmation, type: String, nils: true

  validate do
    add_error(
      :password_confirmation,
      :doesnt_match,
      "Your new password and confirmation do not match"
    ) unless params.password == params.confirmation
  end

  # or more simply:

  add_error :password_confirmation, :doesnt_match, "Your new password and confirmation do not match" do
    params.password != params.confirmation
  end

  ...
end
```

If the validate method returns a Promise, then execution will wait until the Promise resolves.  If the Promise fails, then the current validation fails.

`abort!` can be called from within `validate` or `add_error` to exit the Operation immediately.  Otherwise, all validations will be run and collected together, and the Operation will move onto the `failed` track.  If `abort!` is called within an `add_error` callback the error will be added before aborting.

You can also raise an exception directly in validate if appropriate.  If a `Hyperstack::AccessViolation` exception is raised the Operation will immediately abort, otherwise just the current validation fails.

To avoid further validations if there are any failures in the basic parameter validations, this can be added

```ruby
  validate { abort! if has_errors? }
```

before the first `validate` or `add_error` call.  

### Handling Failed Operations

Because Operations always return a promise, the Promise's `fail` method can be used on the Operation's result to detect failures.

```ruby
QuickCheckout.run(sku: selected_item, qty: selected_qty)
.then do
  # show confirmation
end
.fail do |exception|
  # whatever exception was raised is passed to the fail block
end
```

Failures to validate params result in `Hyperstack::ValidationException` which contains a [Mutations error object](https://github.com/cypriss/mutations#what-about-validation-errors).

```ruby
MyOperation.run.fail do |e|
  if e.is_a? Hyperstack::ValidationException
    e.errors.symbolic     # hash: each key is a parameter that failed validation,
                          # value is a symbol representing the reason
    e.errors.message      # same as symbolic but message is in English
    e.errors.message_list # array of messages where failed parameter is
                          # combined with the message
  end
end
```

### Instance Versus Class Execution Context

Typically the Operation's steps are declared and run in the context of an instance of the Operation.  An instance of the Operation is created, runs and is thrown away.  

Sometimes it's useful to run a step (or other macro such as `validate`) in the context of the class.  This is useful especially for caching values between calls to the Operation.  This can be done by defining the steps in the class context, or by providing the option `scope: :class` to the step.

Note that the primary use should be in interfacing to an outside APIs. Application state should not be hidden inside an Operation, and it should be moved to a Store.


```ruby
class GetRandomGithubUser < Hyperstack::Operation
  def self.reload_users
    @promise = HTTP.get("https://api.github.com/users?since=#{rand(500)}").then do |response|
      @users = response.json.collect do |user|
        { name: user[:login], website: user[:html_url], avatar: user[:avatar_url] }
      end
    end
  end
  self.class.step do # as one big step
    return @users.delete_at(rand(@users.length)) unless @users.blank?
    reload_users unless @promise && @promise.pending?
    @promise.then { run }
  end
end
# or
class GetRandomGithubUser < Hyperstack::Operation
  class << self # as 4 steps - whatever you like
    step  { succeed! @users.delete_at(rand(@users.length)) unless @users.blank? }
    step  { succeed! @promise.then { run } if @promise && @promise.pending? }
    step  { self.class.reload_users }
    async { @promise.then { run } }
  end
end
```

An instance of the operation is always created to hold the current parameter values, dispatcher, etc.  The first parameter to a class level `step` block or method (if it takes parameters) will always be the instance.

```ruby
class Interesting < Hyperstack::Operation
  param :increment
  param :multiply
  outbound :result
  outbound :total
  step scope: :class { @total ||= 0 }
  step scope: :class { |op| op.params.result = op.params.increment * op.params.multiply }
  step scope: :class { |op| op.params.total = (@total += op.params.result) }
  dispatch
end
```

### The Boot Operation

Hyperstack includes one predefined Operation, `Hyperstack::Application::Boot`, that runs at system initialization.  Stores can receive `Hyperstack::Application::Boot` to initialize their state.  To reset the state of the application, you can just execute `Hyperstack::Application::Boot`


## Operations can dispatch messages

Hyperstack Operations borrow from the Flux pattern where Operations are dispatchers and Stores are receivers.  The choice to use Operations in this depends entirely on the needs and design of your application.

To illustrate this point, here is the simplest Operation:

```ruby
class Reset < Hyperstack::Operation
end
```

To 'Reset' the system you would say

```ruby
  Reset.run
```

Elsewhere your HyperStores can receive the Reset *Dispatch* using the `receives` macro:

```ruby
class Cart < Hyperstack::Store
  receives Reset do
    mutate.items Hash.new { |h, k| h[k] = 0 }
  end
end
```

Note that multiple stores can receive the same *Dispatch*.

>**Note: Flux pattern vs. Hyperstack Operations** Operations serve the role of both Action Creators and Dispatchers described in the Flux architecture. We chose the name `Operation` rather than `Action` or `Mutation` because we feel it best captures all the capabilities of a `Hyperstack::Operation`.  Nevertheless, Operations are fully compatible with the Flux Pattern.  

### Dispatching With New Parameters

The `dispatch` method sends the `params` object on to any registered receivers.  Sometimes it's useful to add additional outbound params before dispatching.  Additional params can be declared using the `outbound` macro:

```ruby
class AddItemToCart < Hyperstack::Operation
  param :sku, type: String
  param qty: 1, type: Integer, minimum: 1
  outbound :available

  step { HTTP.get('/inventory/#{params.sku}/qty') }
  step { |response| params.available = response.to_i }
  step { fail if params.qty > params.available }
  dispatch
end
```

### Dispatching messages or invoking steps (or both)?

Facebook is very keen on their Flux architecture where messages are dispatched between receivers. In an extensive and complicated front end application it is easy to see why they are drawn to this architecture as it creates an independence and isolation between Components.

As stated earlier in this documentation, the `step` idea came from Trailblazer, which is an alternative Rails architecture that posits that business functionality should not be kept in the Models, Controllers or Views.

In designing Hyperstack's Isomorphic Operations (which would run on the client and the server), we decided to borrow from the best of both architectures and let Operations work in either way.  The decision as to adopt the dispatching or stepping based model is left down to the programmer as determined by their preference or the needs of their application.

## ServerOps can be used to replace boiler-plate APIs

Some Operations simply do not make sense to run on the client as the resources they depend on may not be available on the client. For example, consider an Operation that needs to send an email - there is no mailer on the client so the Operation has to execute from the server.

That said, with our highest goal being developer productivity, it should be as invisible as possible to the developer where the Operation will execute. A developer writing front-end code should be able to invoke a server-side resource (like a mailer) just as easily as they might invoke a client-side resource.

Hyperstack `ServerOps` replace the need for a boiler-plate HTTP API. All serialization and de-serialization of params are handled by Hyperstack. Hyperstack automagically creates the API endpoint needed to invoke a function from the client which executes on the server and returns the results (via a Promise) to the calling client-side code.

### Server Operations

Operations will run on the client or the server. However, some Operations like `ValidateUserDefaultCC` probably need to check information server side and make secure API calls to our credit card processor.  Rather than build an API and controller to "validate the user credentials" you just specify that the operation must run on the server by using the `Hyperstack::ServerOp` class.

```ruby
class ValidateUserCredentials < Hyperstack::ServerOp
  param :acting_user
  add_error :acting_user, :no_valid_default_cc, "No valid default credit card" do
    !params.acting_user.has_default_cc?
  end
end
```

A Server Operation will always run on the server even if invoked on the client.  When invoked from the client, the ServerOp will receive the `acting_user` param with the current value that your ApplicationController's `acting_user` method returns.   Typically the `acting_user` method will return either some User model or nil (if there is no logged in user.)  It's up to you to define how `acting_user` is computed, but this is easily done with any of the popular authentication gems.  Note that unless you explicitly add `nils: true` to the param declaration, nil will not be accepted.

> **Note regarding Rails Controllers:** Hyperstack is quite flexible and rides along side Rails, without interfering. So you could still have your old controllers, and invoke them the "non-Hyperstack" way by doing say an HTTP.post from the client, etc. Hyperstack adds a new mechanism for communicating between client and server called the Server Operation (which is a subclass of Operation.) A ServerOp has no implication on your existing controllers or code, and if used replaces controllers and client side API calls. HyperModel is built on top of Rails ActiveRecord models, and Server Operations, to keep models in sync across the application. ActiveRecord models that are made public (by moving them to the Hyperstack/models folder) will automatically be synchronized across the clients and the server (subject to permissions given in the Policy classes.)
Like Server Operations, HyperModel completely removes the need to build controllers, and client side API code. However all of your current active record models, controllers will continue to work unaffected.


As shown above, you can also define a validation to ensure further that the acting user (with perhaps other parameters) is allowed to perform the operation.  In the above case that is the only purpose of the Operation.   Another typical use would be to make sure the current acting user has the correct role to perform the operation:

```ruby
  ...
  validate { raise Hyperstack::AccessViolation unless params.acting_user.admin? }
  ...
```

You can bake this kind logic into a superclass:

```ruby
class AdminOnlyOp < Hyperstack::ServerOp
  param :acting_user
  validate { raise Hyperstack::AccessViolation unless params.acting_user.admin? }
end

class DeleteUser < AdminOnlyOp
  param :user
  add_error :user, :cant_delete_user, "Can't delete yourself, or the last admin user" do
    params.user == params.acting_user || (params.user.admin? && AdminUsers.count == 1)
  end
end
```

Because Operations always return a Promise, there is nothing to change on the client to call a Server Operation. A Server Operation will return a Promise that will be resolved (or rejected) when the Operation completes (or fails) on the server.  

### Isomorphic Operations

Unless the Operation is a Server Operation, it will run where it was invoked.   This can be handy if you have an Operation that needs to run on both the server and the client.  For example, an Operation that calculates the customers discount will want to run on the client so the user gets immediate feedback, and then will be run again on the server when the order is submitted as a double check.


### Parameters and ServerOps

You cannot pass an object from the client to the server as a parameter as the server has no way of knowing the state of the object. Hyperstack takes a traditional implementation approach where an id (or some unique identifier) is passed as the parameter and the receiving code finds and created an instance of that object. For example:

```ruby
class IndexBookOp < Hyperstack::ServerOp
  param :book_id
  step { index_book Book.find_by_id params.book_id }
end
```

### Restricting server code to the server

There are valid cases where you will not want your ServerOp's code to be on the client yet still be able to invoke a ServerOp from client or server code. Good reasons for this would include:

+ Security concerns where you would not want some part of your code on the client
+ Size of code, where there will be unnecessary code downloaded to the client
+ Server code using backticks (`) or the %x{ ... } sequence, both of which are interpreted on the client as escape to generate JS code.

To accomplish this, you wrap the server side implementation of the ServerOp in a `RUBY_ENGINE == 'opal'` test which acts as a compiler directive so that this code is not compiled by Opal.

There are several strategies you can use to apply the RUBY_ENGINE == 'opal' guard to your code.

```ruby
# strategy 1:  guard blocks of code and declarations that you don't want to compile to the client
class MyServerOp < Hyperstack::ServerOp
  # stuff that is okay to compile on the client
  # ... etc
  unless RUBY_ENGINE == 'opal'
     # other code that should not be compiled to the client...
  end
end
```

```ruby
# strategy 2:  guard individual methods
class MyServerOp < Hyperstack::ServerOp
  # stuff that is okay to compile on the client
  # ... etc
  def my_secret_method
     # do something we don't want to be shown on the client
   end unless RUBY_ENGINE == 'opal'
end
```

```ruby
# strategy 3:  describe class in two pieces
class MyServerOp < Hyperstack::ServerOp; end  # publically declare the operation
# provide the private implementation only on the server
class MyServerOp < Hyperstack::ServerOp
  #
end unless RUBY_ENGINE == 'opal'
```

Here is a fuller example:

```ruby
# app/Hyperstack/operations/list_files.rb
class ListFiles < Hyperstack::ServerOp
  param :acting_user, nils: true
  param pattern: '*'
  step {  run_ls }

  # because backticks are interpreted by the Opal compiler as escape to JS, we
  # have to make sure this does not compile on the client
  def run_ls
    `ls -l #{params.pattern}`
  end unless RUBY_ENGINE == 'opal'
end

# app/Hyperstack/components/app.rb
class App < Hyperstack::Component
  state files: []

  after_mount do
    @pattern = ''
    every(1) { ListFiles.run(pattern: @pattern).then { |files| mutate.files files.split("\n") } }
  end

  render(DIV) do
    INPUT(defaultValue: '')
    .on(:change) { |evt| @pattern = evt.target.value }
    DIV(style: {fontFamily: 'Courier'}) do
      state.files.each do |file|
        DIV { file }
      end
    end
  end
end
```

### Dispatching From Server Operations

You can also broadcast the dispatch from Server Operations to all authorized clients.  The `dispatch_to` will determine a list of *channels* to broadcast the dispatch to:

```ruby
class Announcement < Hyperstack::ServerOp
  # no acting_user because we don't want clients to invoke the Operation
  param :message
  param :duration, type: Float, nils: true
  # dispatch to the built-in Hyperstack::Application Channel
  dispatch_to Hyperstack::Application
end

class CurrentAnnouncements < Hyperstack::Store
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

As seen above broadcasting is done over a *Channel*.  Any Ruby class (including Operations) can be used as *class channel*.  Any Ruby class that responds to the `id` method can be used as an *instance channel.*  

For example, the `User` active record model could be a used as a channel to broadcast to *all* users.  Each user instance could also be a separate instance channel that would be used to broadcast to a specific user.

The purpose of having channels is to restrict what gets broadcast to who, therefore typically channels represent *connections* to

+ the application (represented by the `Hyperstack::Application` class)
+ or some function within the application (like an Operation)
+ or some class which is *authenticated* like a User or Administrator,
+ instances of those classes,
+ or instances of classes in some relationship - like a `team` that a `user` belongs to.

A channel can be created by including the `Hyperstack::Policy::Mixin`,
which gives three class methods: `regulate_class_connection` `always_allow_connection` and `regulate_instance_connections`.  

For example...

```ruby
class User < ActiveRecord::Base
  include Hyperstack::Policy::Mixin
  regulate_class_connection { self }  
  regulate_instance_connection { self }
end
```

will attach the current acting user to the  `User` channel (which is shared with all users) and to that user's private channel.

Both blocks execute with `self` set to the current acting user, but the return value has a different meaning.  If `regulate_class_connection` returns any truthy value, then the class level connection will be made on behalf of the acting user.  On the other hand, if `regulate_instance_connection` returns an array (possibly nested) or Active Record relationship then an instance connection is made with each object in the list.  So, for example, you could add:

```ruby
class User < ActiveRecord::Base
  has_many chat_rooms
  regulate_instance_connection { chat_rooms }
  # we will connect to all the chat room channels we are members of
end
```

To broadcast to all users, the Operation would have

```ruby
  dispatch_to { User } # dispatch to the User class channel
```

or to send an announcement to a specific user

```ruby
class PrivateAnnouncement < Hyperstack::ServerOp
  param :receiver
  param :message
  # dispatch_to can take a block if we need to
  # dynamically compute the channels
  dispatch_to { params.receiver }
end
...
  # somewhere else in the server
  PrivateAnnouncement.run(receiver: User.find_by_login(login), message: 'log off now!')
```  

The above will work if `PrivateAnnouncement` is invoked from the server, but usually, some other client would be sending the message so the operation could look like this:

```ruby
class PrivateAnnouncement < Hyperstack::ServerOp
  param :acting_user
  param :receiver
  param :message
  validate { raise Hyperstack::AccessViolation unless params.acting_user.admin? }
  validate { params.receiver = User.find_by_login(receiver) }
  dispatch_to { params.receiver }
end
```

On the client::

```ruby
  PrivateAnnouncement.run(receiver: login_name, message: 'log off now!').fail do
    alert('message could not be sent')
  end
```

and elsewhere in the client code, there would be a component like this:

```ruby
class Alerts < Hyperstack::Component
  include Hyperstack::Store::Mixin
  # for simplicity we are going to merge our store with the component
  state alert_messages: [] scope: :class
  receives PrivateAnnouncement { |params| mutate.alert_messages << params.message }
  render(DIV, class: :alerts) do
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

This will (in only 28 lines of code)
+ associate a channel with each logged in user
+ invoke the PrivateAnnouncement Operation on the server (remotely from the client)
+ validate that there is a logged in user at that client
+ validate that we have a non-nil, non-blank receiver and message
+ validate that the acting_user is an admin
+ look up the receiver in the database under their login name
+ dispatch the parameters back to any clients where the receiver is logged in
+ those clients will update their alert_messages state and
+ display the message


The `dispatch_to` callback takes a list of classes, representing *Channels.*  The Operation will be dispatched to all clients connected to those Channels.   Alternatively `dispatch_to` can take a block, a symbol (indicating a method to call) or a proc.  The block, proc or method should return a single Channel, or an array of Channels, which the Operation will be dispatched to.   The dispatch_to callback has access to the params object.  For example, we can add an optional `to` param to our Operation, and use this to select which Channel we will broadcast to.

```ruby
class Announcement < Hyperstack::Operation
  param :message
  param :duration
  param to: nil, type: User
  # dispatch to the Users channel only if specified otherwise announcement is application wide
  dispatch_to { params.to || Hyperstack::Application }
end
```

### Defining Connections in ServerOps

The policy methods `always_allow_connection` and `regulate_class_connection` may be used directly in a ServerOp class.  This will define a channel dedicated to that class, and will also dispatch to that channel when the Operation completes.

```ruby
class Announcement < Hyperstack::ServerOp
  # all clients will have an Announcement Channel which will
  # receive all dispatches from the Announcement Operation
  always_allow_connection
end
```

```ruby
class AdminOps < Hyperstack::ServerOp
  # subclasses can be invoked from the client if an admin is logged in
  # and all other clients that have a logged in admin will receive the dispatch
  regulate_class_connection { acting_user.admin? }
  param :acting_user
  validate { param.acting_user.admin? }
end
```

### Regulating Dispatches in Policy Classes

Regulations and dispatch lists can be grouped and specified in Policy files, which are by convention kept in the Rails `app/policies` directory.

```ruby
# app/policies/announcement_policy.rb
class AnnouncementPolicy
  always_allow_connection
  dispatch_to { params.acting_user }
end

# app/policies/user_policy.rb
class UserPolicy
  regulate_instance_connection { self }
end
```

### Serialization

If you need to control serialization and deserialization across the wire you can define the following *class* methods:

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
  # default just returns the input hash
end

def self.deserialize_dispatch(object)
  # recieves whatever was returned from serialize_to_server
  # (param_name => value pairs by default)
  # must return a hash of param_name => value pairs
  # by default this returns object
end
```

### Accessing the Controller

ServerOps have the ability to receive the "controller" as a param. This is handy for low-level stuff (like login) where you need access to the controller. There is a subclass of ServerOp called ControllerOp that simply declares this param and will delegate any controller methods to the controller param. So within a `ControllerOp` if you say `session` you will get the session object from the controller.

Here is a sample of the SignIn operation using the Devise Gem:

```ruby
class SignIn < Hyperstack::ControllerOp
  param :email
  inbound :password
  add_error(:email, :does_not_exist, 'that login does not exist') { !(@user = User.find_by_email(params.email)) }
  add_error(:password, :is_incorrect, 'password is incorrect') { !@user.valid_password?(params.password)  }
 # no longer have to do this step { params.password = nil }
  step { sign_in(:user, @user)  }
end
```

In the code above there is another parameter type in ServerOps, called inbound, which will not get dispatched.

### Broadcasting to the current_session

Let's say you would like to be able to broadcast to the current session. For example, after the user signs in we want to broadcast to all the browser windows the user happens to have open so that they can update.

For this, we have a `current_session` method in the `ControllerOp` that you can dispatch to.

```ruby
class SignIn < Hyperstack::ControllerOp
  param :email
  inbound :password
  add_error(:email, :does_not_exist, 'that login does not exist') { !(@user = User.find_by_email(params.email)) }
  add_error(:password, :is_incorrect, 'password is incorrect') { !@user.valid_password?(params.password)  }
  step { sign_in(:user, @user)  }
  dispatch_to { current_session }
end
```

The Session channel is special so to attach to the application to it you would say in the top level component:

```ruby
class App < Hyperstack::Component
  after_mount :connect_session
end
```

## Additional information

### Operation Capabilities

Operations have the following capabilities:

+ Can easily be chained because they always return Promises
+ declare both their parameters and what they will dispatch
+ Parameters can be validated and type checked
+ Can run remotely on the server
+ Can be dispatched from the server to all authorized clients.
+ Can hold their own state data when appropriate
+ Operations also serves as the bridge between client and server
+ An operation can run on the client or the server and can be invoked remotely.

**Use Operations as you choose**. This architecture is descriptive but not prescriptive. Depending on the needs of your application and your overall thoughts on architecture, you may need a little or a lot of the functionality provided by Operations. If you chose, you could keep all your business logic in your Models, Stores or Components - we suggest that it is better application design not to do this, but the choice is yours.

### Background

The design of Hyperstack's Operations have been inspired by three concepts: [Trailblazer Operations](http://trailblazer.to/gems/operation/2.0/) (for encapsulating business logic in `steps`), the [Flux pattern](https://facebook.github.io/flux/) (for dispatchers and receivers), and the [Mutation Gem](https://github.com/cypriss/mutations) (for validating params).

### Hyperstack Operations compared to Flux

| Flux | Hyperstack |
|-----| --------- |
| Action | Hyperstack::Operation subclass |
| ActionCreator | `Hyperstack::Operation.step/failed/async` methods |
| Action Data | Hyperstack::Operation parameters |
| Dispatcher | `Hyperstack::Operation#dispatch` method |
| Registering a Store | `Store.receives` |
