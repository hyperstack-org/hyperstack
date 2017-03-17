#  Hyper-Operation

## Hyper-Operation gem

Operations encapsulate business logic. In a traditional MVC architecture, Operations end up either in Controllers, Models or some other secondary construct such as service objects, helpers, or concerns. Here they are first class objects. Their job is to mutate state in the Stores and Models.

+ Hyperloop::Operation is the base class for Operations.
+ An Operation orchestrates the updating of the state of your system.
+ Operations also wrap asynchronous operations such as HTTP API requests.
+ Operations serve the role of both Action Creators and Dispatchers described in the Flux architecture.
+ Operations also serve as the bridge between client and server. An operation can run on the client or the server, and can be invoked remotely.

## Documentation and Help

+ Please see the [ruby-hyperloop.io](http://ruby-hyperloop.io/) website for documentation.
+ Join the Hyperloop [gitter.io](https://gitter.im/ruby-hyperloop/chat) chat for help and support.

## Basic Installation and Setup

The easiest way to install is to use the `hyper-rails` gem.

<<<<<<< HEAD
### Installation

**Note: only runs with rails currently.**

Add `gem 'hyper-operation'` to your Gemfile
Add `//= require hyperloop-loader` to your application.rb

If you want operations to interact between server and client you will have to pick a transport:
```ruby
# initializers/hyperloop.rb
Hyperloop.configuration do |config|

  # to use Action Cable
    config.transport = :action_cable # for rails 5+

  # to use Pusher (see www.pusher.com)
    config.transport = :pusher
    config.opts = {
      app_id: "pusher application id",
      key: "pusher public key",
      secret: "pusher secret key"
    }

  # to use Pusher Fake (creates a fake pusher service)
    # Its a bit weird:  You have to define require pusher and
    # define some FAKE pusher keys first, then bring in pusher-fake
    # the actual key values don't matter just the order!!!
    require 'pusher'  
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"      # don't bother changing these strings
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require 'pusher-fake/support/base'
    # then setup your config like pusher but merge in the pusher fake
    # options
    config.transport = :pusher
    config.opts = {
      app_id: Pusher.app_id,
      key: Pusher.key,
      secret: Pusher.secret
    }.merge(PusherFake.configuration.web_options)

  # For down and dirty simplicity use polling:
    config.transport = :simple_poller
    # change this to slow down polling, default is much faster
    # and hard to debug
    config.opts = { seconds_between_poll: 2 }
end
```

You will also have to add at least one channel policy to authorize the connection between clients and the server.

```ruby
# app/policies/application_policy.rb
class Hyperloop::ApplicationPolicy
  # allow any client too attach to the Hyperloop::Application for example
  always_allow_connection  
end
```

See the [Channels](#channels) section for more details on authorization.

### Operation Structure
=======
1. Add `gem 'hyper-rails'` to your Rails `Gemfile` development section.
2. Install the Gem: `bundle install`
3. Run the generator: `bundle exec rails g hyperloop:install --all`
4. Update the bundle: `bundle update`
>>>>>>> 14990fb3321e5a8b1cc1cb2d859d747695ffd907

Your Isomorphic Operations live in a `hyperloop/operations` folder and your server only Operations in `app/operations`

You will also find an `app/policies` folder with a simple access policy suited for development.  Policies are how you will provide detailed access control to your Isomorphic models.  

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-hyperloop/hyper-operation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code of Conduct](https://github.com/ruby-hyperloop/hyper-operation/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## License

<<<<<<< HEAD
```ruby
class AddItemToCart < Hyperloop::Operation
  param :sku, type: String
  param qty: 1, type: Integer, min: 1
end

class Cart < Hyperloop::Store
  receives AddItemToCart do
    mutate.items[params.sku] += params.qty
  end
end
```

In addition unlike Hyperloop::Component params,  Operation params are *not* reactive, and so you can assign to them as well:
```ruby
  params.some_value = 12
```

The parameter filter types and options are taken from the [Mutations](https://github.com/cypriss/mutations) gem with the following changes:

+ In Hyperloop::Operations all params are declared with the param macro.  
+ The type *can* be specified using the `type:` option.
+ Array and hash types can be shortened to `[]` and `{}`
+ Optional params either have the default value associated with the param name, or by having the `default` option present.
+ All other [Mutation filter options](https://github.com/cypriss/mutations/wiki/Filtering-Input) (such as `:min`) will work the same.

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
class Reset < Hyperloop::Operation
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

Together `step` and `failed` form two *railway tracks*.  Initially execution proceeds down the success track until something goes wrong, then
execution switches to the failure track starting at the next `failed` statement.  Once on the failed track execution continues performing each
`failed` callback and skipping any `step` callbacks.

Failure occurs when either an exception is raised or a promise fails (more on this in the next section.) The Ruby `fail` keyword can be used as a simple way to switch to the failed track.

Both `step` and `failed` can receive any results delivered by the previous step.   If the previous step raised an exception (outside a promise) the failure track will receive the exception object.

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

Within the browser, code does not wait for asynchronous methods (such as HTTP requests or timers) to complete.  Operations use Opal's [Promise library](http://opalrb.org/docs/api/v0.10.3/stdlib/Promise.html) to deal with these situations cleanly.  A Promise is an object that has three states:  It is either still pending, or has been rejected (i.e. failed), or has been successfully resolved.  A promise can have callbacks attached to either the failed or resolved state, and these callbacks will be executed once the promise is resolved or rejected.

If a `step` or `failed` callback returns a pending promise then the execution of the operation is suspended, and the Operation will return the promise to the caller.  If there is more track ahead, then execution will resume on the next step when the promise is resolved.  Likewise if the pending promise is rejected execution will resume on the next `failed` callback.  Because of the way promises work, the operation steps will all be completed before the resolved state is passed along to caller, so everything will execute in its original order.

Likewise the Operation's dispatch occurs when the promise resolves as well.

The `async` method can be used to override the waiting behavior.  If a `step` returns a promise, and there is an `async` callback farther down the track, execution will immediately pick up at the `async`.  Any steps in between will still be run when the promise resolves, but their results will not be passed outside of the operation.

These features make it easy to organize, understand and compose asynchronous code:

```ruby
class AddItemToCart < Hyperloop::Operation
  step { HTTP.get('/inventory/#{params.sku}/qty') }
  # previous step returned a promise so next step
  # will execute when that promise resolves
  step { |response| fail if params.qty > response.to_i }
  # once we are sure we have inventory we will dispatch
  # to any listening stores.
end
```

Operations will *always* return a *Promise*.  If an Operation has no steps that return a promise the value of the last step will be wrapped in a resolved promise.  This lets you easily chain Operations, regardless of their internal implementation:

```ruby
class QuickCheckout < Hyperloop::Operation
  param :sku, type: String
  param qty: 1, type: Integer, minimum: 1

  step { AddItemToCart(params) }
  step ValidateUserDefaultCC
  step Checkout
end
```

You can also use `Promise#when` if you don't care about the order of Operations

```ruby
class DoABunchOStuff < Hyperloop::Operation
  step { Promise.when(SomeOperation.run, SomeOtherOperation.run) }
  # dispatch when both operations complete
end
```

### Early Exits with `abort!` and `succeed!`

In any `step` or `failed` callback, you may do an immediate exit from the Operation using the `abort!` and `succeed!` methods.  The `abort!` method returns a failed Promise with any supplied parameters.  The `succeed!` method does an immediate dispatch, and returns a resolved Promise with any supplied parameters.  If `succeed!` is used in a `failed` callback, it will override the failed status of the Operation.  This is especially useful if you want to dispatch in spite of failures:

```ruby
class Pointless < Hyperloop::Operation
  step { fail }       # go to failure track
  failed { succeed! } # dispatch and exit
end
```

### The `validate` and `add_error` methods

An Operation can also have a number of `validate` callbacks which will run before the first step.  This is a handy place to put any additional validations.  In the validate method you can add validation type messages using the `add_error` method, and these will be passed along like any other param validation failures.

```ruby
class UpdateProfile < Hyperloop::Operation
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

If the validate method returns a promise, then execution will wait until the promise resolves.  If the promise fails, then the current validation fails.

You may also call `abort!` from within `validate` or `add_error` to immediately exit the Operation.  Otherwise all validations will be run and collected together and the Operation will move onto the `failed` track.  If `abort!` is called within an `add_error` callback the error will be added before aborting.

You can also raise an exception directly in validate if appropriate.  If a `Hyperloop::AccessViolation` exception is raised the Operation will immediately abort, otherwise just the current validation fails.

If you want to avoid further validations if there are any failures in the basic parameter validations you can add do add this
```ruby
  validate { abort! if has_errors? }
```
before the first `validate` or `add_error` call.  

### Handling Failed Operations

Because Operations always return a promise, you can use the Promise's `fail` method on the Operation's result to detect failures.

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

### Running Operations

You can run an Operation by using ...
+ the Operation class name as a method:  
```ruby
MyOperation(...params...)
```
+ the `run` method:  
```ruby
MyOperation.run ...params...
```
+ the `then` and `fail` methods, which will dispatch the operation and attach a promise handler:  
```ruby
MyOperation.then(...params...) { alert 'operation completed' }
```

### The `Hyperloop::ServerOp` class

Operations will run on the client or the server.  Some Operations like `ValidateUserDefaultCC` probably need to check information server side, and make secure API calls to our credit card processor.  Rather than build an API and controller to "validate the user credentials" you simply specify that the operation must run on the server by using the `Hyperloop::ServerOp` class.

```ruby
class ValidateUserCredentials < Hyperloop::ServerOp
  param :acting_user
  add_error :acting_user, :no_valid_default_cc, "No valid default credit card" do
    !params.acting_user.has_default_cc?
  end
end
```

A Server Operation will always run on the server even if invoked on the client.  When invoked from the client Server Operations will receive the `acting_user` param with the current value that your ApplicationController's `acting_user` method returns.   Typically the `acting_user` method will return either some User model, or nil (if there is no logged in user.)  Its up to you to define how `acting_user` is computed, but this is easily done with any of the popular authentication gems.  Note that unless you explicitly add `nils: true` to the param declaration, nil will not be accepted.

As shown above you can also define a validation to further insure that the acting user (with perhaps other parameters) is allowed to perform the operation.  In the above case that is the only purpose of the Operation.   Another typical use would be to make sure the current acting user has the correct role to perform the operation:

```ruby
  ...
  validate { raise Hyperloop::AccessViolation unless params.acting_user.admin? }
  ...
```

You can bake this kind logic into a superclass:

```ruby
class AdminOnlyOp < Hyperloop::ServerOp
  param :acting_user
  validate { raise Hyperloop::AccessViolation unless params.acting_user.admin? }
end

class DeleteUser < AdminOnlyOp
  param :user
  add_error :user, :cant_delete_user, "Can't delete yourself, or the last admin user" do
    params.user == params.acting_user || (params.user.admin? && AdminUsers.count == 1)
  end
end
```

Because Operations always return a promise, there is nothing to change on the client to call a Server Operation. A Server Operation will return a promise that will be resolved (or rejected) when the Operation completes (or fails) on the server.  

### Dispatching From Server Operations

You can also broadcast the dispatch from Server Operations to all authorized clients.  The `dispatch_to` will determine a list of *channels* to broadcast the dispatch to:

```ruby
class Announcement < Hyperloop::ServerOp
  # no acting_user because we don't want clients to invoke the Operation
  param :message
  param :duration, type: Float, nils: true
  # dispatch to the builtin Hyperloop::Application Channel
  dispatch_to Hyperloop::Application
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

As seen above broadcasting is done over a *Channel*.  Any Ruby class (including Operations) can be used as *class channel*.  Any Ruby class that responds to the `id` method can be used as an *instance channel.*  

For example the `User` active record model could be a used as channel to broadcast to *all* users.  Each user instance could also be a separate instance channel that would be used to broadcast to a specific user.

The purpose of having channels is to restrict what gets broadcast to who, therefore typically channels represent *connections* to

+ the application (represented by the `Hyperloop::Application` class)
+ or some function within the application (like an Operation)
+ or some class which is *authenticated* like a User or Administrator,
+ instances of those classes,
+ or instances of classes in some relationship - like a `team` that a `user` belongs to.

You create a channel by including the `Hyperloop::Policy::Mixin`,
which gives you three class methods: `regulate_class_connection` `always_allow_connection` and `regulate_instance_connections`.  For example:

```ruby
class User < ActiveRecord::Base
  include Hyperloop::Policy::Mixin
  regulate_class_connection { self }  
  regulate_instance_connection { self }
end
```

will attach the current acting user to the  `User` channel (which is shared with all users) and to that user's private channel.

Both blocks execute with `self` set to the current acting user, but the return value has a different meaning.  If `regulate_class_connection` returns any truthy value, then the class level connection will be made on behalf of the acting user.  On the other hand if `regulate_instance_connection` returns an array (possibly nested) or Active Record relationship then an instance connection is made with each object in the list.  So for example you could add:

```ruby
class User < ActiveRecord::Base
  has_many chat_rooms
  regulate_instance_connection { chat_rooms }
  # we will connect to all the chat room channels we are members of
end
```

Now if we want to broadcast to all users our Operation would have

```ruby
  dispatch_to { User } # dispatch to the User class channel
```

or to send an announcement to a specific user

```ruby
class PrivateAnnouncement < Hyperloop::ServerOp
  param :receiver
  param :message
  # dispatch_to can take a block if we need to
  # dynamically compute the channels
  dispatch_to { params.receiver }
end
...
  # somewhere else in the server
  PrivateAnnouncement(receiver: User.find_by_login(login), message: 'log off now!')
```  

The above will work if `PrivateAnnouncement` is invoked from the server, but usually some other client would be sending the message so the operation could look like this:

```ruby
class PrivateAnnouncement < Hyperloop::ServerOp
  param :acting_user
  param :receiver
  param :message
  validate { raise Hyperloop::AccessViolation unless params.acting_user.admin? }
  validate { params.receiver = User.find_by_login(receiver) }
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
  include Hyperloop::Store::Mixin
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
+ lookup the receiver in the database under their login name
+ dispatch the parameters back to any clients where the receiver is logged in
+ those clients will update their alert_messages state and
+ display the message


The `dispatch_to` callback takes a list of classes, representing *Channels.*  The Operation will be dispatched to all clients connected on those Channels.   Alternatively `dispatch_to` can take a block, a symbol (indicating a method to call) or a proc.  The block, proc or method should return a single Channel, or an array of Channels, which the Operation will be dispatched to.   The dispatch_to callback has access to the params object.  For example we can add an optional `to` param to our Operation, and use this to select which Channel we will broadcast to.

```ruby
class Announcement < Hyperloop::Operation
  param :message
  param :duration
  param to: nil, type: User
  # dispatch to the Users channel only if specified otherwise announcement is application wide
  dispatch_to { params.to || Hyperloop::Application }
end
```

### Defining Connections in ServerOps

The policy methods `always_allow_connection` and `regulate_class_connection` may be used directly in a ServerOp class.  This will define a channel dedicated to that class, and will also dispatch to that channel when the Operation completes.

```ruby
class Announcement < HyperLoop::ServerOp
  # all clients will have a Announcement Channel which will
  # receive all dispatches from the Annoucement Operation
  always_allow_connection
end
```

```ruby
class AdminOps < HyperLoop::ServerOp
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
  # default is just return the input hash
end

def self.deserialize_dispatch(object)
  # recieves whatever was returned from serialize_to_server
  # (param_name => value pairs by default)
  # must return a hash of param_name => value pairs
  # by default this returns object
end
```

### Isomorphic Operations

Unless the Operation is a Server Operation it will run where it was invoked.   This can be handy if you have an Operation that needs to run on both the server and the client.  For example an Operation that calculates the customers discount, will want to run on the client so the user gets immediate feedback, and then will be run again on the server when the order is submitted as a double check.

### Dispatching With New Parameters

The `dispatch` method sends the `params` object on to any registered receivers.  Sometimes it's useful for the to add additional outbound params before dispatching.  Additional params can be declared using the `outbound` macro:

```ruby
class AddItemToCart < Hyperloop::Operation
  param :sku, type: String
  param qty: 1, type: Integer, minimum: 1
  outbound :available

  step { HTTP.get('/inventory/#{params.sku}/qty') }
  step { |response| params.available = response.to_i }
  step { fail if params.qty > params.available }
  dispatch
end
```

### Instance Verses Class Execution Context

Normally the Operation's steps are declared and run in the context of an instance of the Operation.  An instance of the Operation is created, runs and is thrown away.  

Sometimes it's useful to run a step (or other macro such as `validate`) in the context of the class.  This is useful especially for caching values between calls to the Operation.  You can do this by defining the steps in the class context, or by providing the option `scope: :class` to the step.

Note that the primary use should be in interfacing to outside APIs.  Don't hide your application state inside an Operation - Move it to a Store.

```ruby
class GetRandomGithubUser < Hyperloop::Operation
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
class GetRandomGithubUser < Hyperloop::Operation
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
class Interesting < Hyperloop::Operation
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

### The `Hyperloop::Application::Boot` Operation

Hyperloop includes one predefined Operation, `Hyperloop::Application::Boot`, that runs at system initialization.  Stores can receive `Hyperloop::Application::Boot` to initialize their state.  To reset the state of the application you can simply execute `Hyperloop::Application::Boot`

### Flux and Operations

Hyperloop is a merger of the concepts of the Flux pattern, the [Mutation Gem](https://github.com/cypriss/mutations), and Trailblazer Operations.

We chose the name `Operation` rather than `Action` or `Mutation` because we feel it best captures all the capabilities of a `Hyperloop::Operation`.  Nevertheless Operations are fully compatible with the Flux Pattern.  

| Flux | HyperLoop |
|-----| --------- |
| Action | Hyperloop::Operation subclass |
| ActionCreator | `Hyperloop::Operation.step/failed/async` methods |
| Action Data | Hyperloop::Operation parameters |
| Dispatcher | `Hyperloop::Operation#dispatch` method |
| Registering a Store | `Store.receives` |

In addition Operations have the following capabilities:

+ Can easily be chained because they always return promises.
+ Clearly declare both their parameters, and what they will dispatch.
+ Parameters can be validated and type checked.
+ Can run remotely on the server.
+ Can be dispatched from the server to all authorized clients.
+ Can hold their own state data when appropriate.

## Documentation and Help

+ Please see the [ruby-hyperloop.io](http://ruby-hyperloop.io/) website for documentation.
+ Join the Hyperloop [gitter.io](https://gitter.im/ruby-hyperloop/chat) chat for help and support.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-hyperloop/hyper-store. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code of Conduct](https://github.com/ruby-hyperloop/hyper-store/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## License

=======
>>>>>>> 14990fb3321e5a8b1cc1cb2d859d747695ffd907
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
