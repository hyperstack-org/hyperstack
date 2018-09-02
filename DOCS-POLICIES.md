# Hyperloop Policies

## Authorization

Access to your Isomorphic Models is controlled by *Policies* that describe how the current *acting_user* and *channels* may access your Models.

Each browser session has an *acting_user* (which may be nil) and you will define `create`, `update`, and `destroy` policies giving (or denying) the `acting_user` the ability to do these operations.

Read and *broadcast* access is defined based on *channels* which are connected based again on the current `acting_user`.  Read access is initiated when a specific browser tries to read a record attribute, and broadcasts are initiated whenever a model changes.

An application can have several channels and each channel and each active record model can have different policies to determine which attributes are sent when a record changes.

For example a Todo application might have an *instance* of a channel for each currently logged in user; an instance of a channel for each team if that team has one or more logged in users; and a general `AdminUser` channel shared by all administrators that are logged in.

Lets say a specific `Todo` changes, which is part of team id 123's Todo list, and users 7 and 8 who are members of that team are currently logged in as well as two of the `AdminUsers`.  

When the `Todo` changes we want all the attributes of the `Todo` broadcast on team 123's channel, as well on the `AdminUser`'s channel.  Now lets say User 7 sends User 8 a private message, adding a new record to the `Message` model.  This update should only be sent to user 7 and user 8's private channels, as well as to the AdminUser channel.

We can define all these policies by creating the following classes:

```ruby
class UserPolicy # defines policies for the User class
  # The regulate_instance_connections method enables instances of the User
  # class to be treated as a channel.  

  # The policy is defined by a block that is executed in the context of the
  # current acting_user.

  # For our User instance connection the policy is that there must be a
  # logged-in user, and the connection is made to that user:
  regulate_instance_connections { self }
  # If there is no logged in user self will be nil, and no connection will be
  # made.
end

class TeamPolicy # defines policies for the Team class  
  # Users can only connect to Teams that they belong to
  regulate_instance_connections { teams }
end

class AdminUserPolicy
  # All AdminUsers share the same connection so we setup a class wide
  # connection available to any users who are admins.
  regulate_class_connection { admin? }

  # The AdminUser channel will receive all attributes
  # of all records, unless the attribute is named :password
  regulate_all_broadcasts do |policy|
    policy.send_all_but(:password)
  end
end

class TodoPolicy
  # Policies can be established for models that are not channels as well.

  # The regulate_broadcast method will describe what attributes to send
  # when a Todo model changes.  

  # The blocks of broadcast policies run in the context of the changed model
  # so we have access to all the models methods.  In this case Todo
  # belongs to a Team through the 'team' relationship.
  regulate_broadcast do |policy|
    # send all Todo attributes to the todo's team channel
    policy.send_all.to(team)
  end
end

class MessagePolicy
  # Broadcast policies can be arbitrarily complex.  In this case we
  # want to broadcast the entire message to the sender and the
  # recipient's instance channels.  
  # In addition if the message is not private, then we want to send to all
  # the team instance channels that are shared between the sender and
  # recipient's teams.
  regulate_broadcast do |policy|
    policy.send_all.to(sender, recipient)
    policy.send_all.to(sender.teams.merge(recipient.teams)) unless private?
  end
end
```

Before we begin using these channels and policies we need to first define the Reactive-Record `acting_user` method in our ApplicationController:

```ruby
class ApplicationController < ActionController::Base
  def acting_user
    # The acting_user method should return nil, or some object that corresponds to a
    # logged in user.  Specifics will depend on your application and whatever other
    # authentication mechanisms you are using.
    @acting_user ||= session[:current_user_id] && User.find_by_id(session[:current_user_id])
    end
  end
end
```

Note that `acting_user` is also used by ReactiveRecord's permission system.

Our entire set of policies is defined in 29 lines of code of which 8 actually execute the policies.  Our existing classes form the foundation, and we simply add Hyperloop specific policy directives.  Pretty sweet huh?

### Details

Hyperloop uses *Policies* to *regulate* what *connections* are opened between clients and the server and what data is distributed over those connections.

Connections are made on *channels* of data flowing between the server and a number of clients.  Each channel is associated with either a class or an instance of a class.  Typically the channel class represents an entity (or is associated with an entity) that can be authenticated like a `User`, an  `AdminUser`, or a `Team` of users.  A channel associated with the class itself broadcasts data that is received by any member of that class.  A channel associated with an instance is for data that is available only to that specific instance.   

As Models on the server change (i.e. created, updated, or destroyed) the changes are broadcast over open channels.  What specific attributes are sent (if any) is determined by broadcast policies.

Broadcast policies can be associated with Models.  As the Model changes the broadcast policy will regulate what attributes of the changed model will be sent over which channels.  

Broadcast policies can also be associated with a channel and will regulate *all* model changes over specific channels.  In other words this is just a convenient way to associate a common policy with *all* Models.

Note that Models that are associated with channels can also broadcast their changes on the same or different channels.

#### Defining Policies and Policy Classes

The best way to define policies is to use a *Policy Class*.  A policy class has the same class name as the class it is regulating, with `Policy` added to the end.  Policy classes are compatible with `Pundit`, and you can add regular pundit policies as well.

Policies are defined using four methods:
+ `regulate_class_connection` controls connections to the class channels,
+ `regulate_instance_connections` controls connections to instance channels,
+ `regulate_broadcast` controls what data will be sent when a model or object changes and,
+ `regulate_all_broadcasts` controls what data will be sent of some channels when any model changes.

In addition `always_allow_connection` is short hand for `regulate_class_connection { true }`

A policy class can be defined for which there is no regulated class.  This is useful for application wide connections, which are typically open even if no one is logged in:

```ruby
#app/policies/application.rb
class ApplicationPolicy
  regulate_class_connection { true }
end
```

Note that by default policy classes go in the `app/policies` directory.  Hyperloop will require all the files in this directory.

If you wish, you can also add policies directly in your Models by including the `Hyperloop::PolicyMethods` module in your model.  You can then use the `regulate_class_connection`, `regulate_instance_connections`, `regulate_all_broadcasts` and `regulate_broadcast` methods directly in the model.

```ruby
class User < ActiveRecord::Base
  include Hyperloop::PolicyMethods
  regulate_class_connection ...
  regulate_instance_connections ...
  regulate_all_broadcasts ...  
  regulate_broadcast ...
end
```

Normally the policy methods are regulating the class with the prefix as the policy, but you can override this by providing specific class names to the policy method.  This allows you to group several different class policies together, and to reuse policies:

```ruby
class ApplicationPolicy
  regulate_connection { ... }  # Application is assumed
  regulate_class_connection(User) { ... }
  # regulate_class_connection, regulate_instance_connections and
  # regulate_all_broadcasts can take a list of channels.
  regulate_all_broadcasts(User, Application)
  # regulate_broadcast takes a list of object classes which
  # may also be channels.
  regulate_broadcast(Todo, Message, User) { ... }
end
```

#### Channels and connection policies

Any ruby class that has a connection policy is a Hyperloop channel. The fully scoped name of the class becomes the root of the channel name.

The purpose of having channels is to restrict what gets broadcast when models change, therefore typically channels represent *connections* to

+ the application, or some function within the application
+ or some class which is *authenticated* like a User or Administrator,
+ instances of those classes,
+ or instances of related classes.

So a channel that is connected to the User class would get information readable by any logged-in user, while a channel that is connected to a specific User instance would get information readable by that specific user.

The `regulate_class_connection` takes a block that will execute in the context of the current acting_user (which may be nil), and if the block returns any truthy value, the connection will be made.

The `regulate_instance_connections` likewise takes a block that is executed in the context of the current acting_user.  The block may do one of following:

+ raise an error meaning the connection cannot be made
+ return a falsy value also meaning the connection cannot be made
+ return a single object meaning the connection can be made to that object
+ return a enumerable of objects meaning the connection can made to any member of the enumerable

Note that the object (or objects) returned are expected to be of the same class as the regulated policy.  

```ruby
# Create a class connection only if the acting_user is non-nil (i.e. logged in:)
regulate_class_connection { self }
# Always open the connection:
regulate_class_connection { true }
# Which can be shortened to:
always_allow_connection
# Create a class level connection if the acting_user is an admin:
regulate_class_connection { admin? }
# Create an instance connection for the current user:
regulate_instance_connections { self }
# Create an instance connection for the current user if the user is an admin:
regulate_instance_connections { self if admin? }
# create an instance_connection to the users' group
regulate_instance_connections { group }
# create an instance connection for any team the user belongs to
regulate_instance_connections { teams }
```

#### Class Names Instances and IDs

While establishing connections, classes are represented as their fully scoped name, and instances are represented as the class name plus the result of calling `id` on the instance.

Typically connections are made to ActiveRecord models, and if those are in the `app/hyperloop/models` folder everything will work fine.

## Acting User

Hyperloop looks for an `acting_user` method typically defined in the ApplicationController and would normally pick up the current session user, and return an appropriate object.

```ruby
class ApplicationController < ActiveController::Base
  def acting_user
    @acting_user ||= session[:current_user_id] && User.find_by_id(session[:current_user_id])
    end
  end
end
```

#### Automatic Connection

Connections to channels available to the current `acting_user` are automatically made on the initial page load.  This behavior can be turned off with the `auto_connect` option.

```ruby
class TeamPolicy
  # Allow current users to establish connections to any teams they are
  # members of, but disable_auto_connect
  regulate_instance_connections(auto_connect: false) { teams }
end
```

Its important to consider turning off automatic connections for cases like the above where the user is likely to be a member of many teams.  Typically the client application will want to dynamically determine which specific teams to connect to given the current state of the application.

### Manually Connecting to Channels

Normally the client will automatically connect to the available channels when a page loads, but you can also
manually connect on the client in response to some user action like logging in, or the user deciding to
display a specific team status on their dashboard.

To manually connect a client use the `Hyperloop.connect` method.  

The `connect` method takes any number of arguments each of which is either a class, an object, a String or Array.

If the argument is a class then the connection will be made to the matching class channel on the server.

```ruby
# connect the client to the AdminUser class channel
Hyperloop.connect(AdminUser)
# if the connection is successful the client will begin getting updates on the
# AdminUser class channel
```

If the argument is an object then a connection will be made to the matching object on the server.

```ruby
# assume current_user is an instance of class User
Hyperloop.connect(current_user)
# current_user.id is used to establish which User instance to connect to on the
# server
```

The argument can also be a string, which matches the name of a class on the server

```ruby
Hyperloop.connect('AdminUser')
# same as AdminUser class
```

or the argument can be an array with a string and the id:

```ruby
Hyperloop.connect(['User', current_user.id])
# same as saying current_user
```

You can make several connections at once as well:
```ruby
Hyperloop.connect(AdminUser, current_user)
```

Finally falsy values are ignored.

You can also send `connect` directly to ActiveRecord models:

```ruby
AdminUser.connect!    # same as Hyperloop.connect(AdminUser)
current_user.connect! # same as Hyperloop.connect(current_user)
```

#### Connection Sequence Summary

For class connections:

1. The client calls `Hyperloop.connect`.
2. Hyperloop sends the channel name to the server.
3. Hyperloop has its own controller which will determine the `acting_user`,
4. and call the channel's `regulate_class_connection` method.
5. If `regulate_class_connection` returns a truthy value then the connection is made,
6. otherwise a 500 error is returned.

For instance connections:

1. The process is the same but the channel name and id are sent to the server.  
2. The Hyperloop controller will do a `find` of the id passed to get the instance,
3. and if successful `regulate_instance_connections` is called,
4. which must return an either the same instance, or an enumerable with that instance as a member.
5. Otherwise a 500 error is returned.

Note that the same sequence is used for auto connections and manually invoked connections.

#### Disconnecting

Calling `Hyperloop.disconnect(channel)` or `channel.disconnect!` will disconnect from the channel.

## Broadcasting and Broadcast Policies

Broadcast policies can be defined for channels using the `regulate_all_broadcasts` method, and for individual objects (typically ActiveRecord models) using the `regulate_broadcast` method.  A `regulate_all_broadcasts` policy is essentially a `regulate_broadcast` that will be run for every record that changes in the system.

After an ActiveRecord Model change is committed, all active class channels run their channel broadcast policies, and then the instance broadcast policy associated with the changing Model is run.  So for any change there may be multiple channel broadcast policies involved, but only one (at most) regulate_broadcast.  

The result is that each channel may get a filtered copy of the record which is broadcast on that channel.

The purpose of the policies then is to determine which channel sees what.  Each broadcast policy receives the instance of the policy which responds to the following methods

+ `send_all`: send all the attributes of the record.
+ `send_only`: send only the listed attributes of the record.
+ `send_all_but`: send all the attributes except the ones listed.

The result of the `send...` method is then directed to the set of channels using the `to` method:

```ruby
policy.send_all_but(:password).to(AdminUser)
```

Within channel broadcast policies the channel is assumed to be the channel in question:

```ruby
class AdminUserPolicy
  regulate_all_broadcasts do |policy|
    policy.send_all_but(:password) #.to(AdminUser) is not needed.
  end
end
```

The `to` method can take any number of arguments:

+ a class naming a channel,
+ an object that is instance channel,
+ an ActiveRecord collection,
+ any falsy value which will be ignored,
+ or an array that will be flattened and merged with the other arguments.

The broadcast policy executes in the context of the model that has just changed, so the policy can use all the methods of that model, especially relationships.  For example:

```ruby
class Message < ActiveRecord::Base
  belongs_to :sender, class: "User"
  belongs_to :recipient, class: "User"
end

class MessagePolicy
  regulate_broadcast do |policy|
    # send all attributes to both the sender, and recipient User instance channels
    policy.send_all.to(sender, recipient)
    # send all attributes to intersection
    policy.send_all.to(sender.teams.merge(recipient.teams)) unless private?
  end
end
```

It is possible that the same channel may be sent a record from different policies, in this case the minimum set of attributes will be sent regardless of the order of the send operations.  For example:

```ruby
policy.send_all_but(:password).to(MyChannel)
# ... later
policy.send_all.to(MyChannel)
# MyChannel gets everything but the password
```

or even

```ruby
policy.send_only(:foo, :bar).to(MyChannel)
policy.send_only(:baz).to(MyChannel)
# MyChannel gets nothing
```

Keep in mind that the broadcast policies are sent a copy of the policy object so you can use helper methods in your policies. Also you can add policy specific methods to your models using `class_eval` thus keeping policy logic out of your models.

So we could for example we can rewrite the above MessagePolicy like this:

```ruby
class MessagePolicy
  Message.class_eval do
    scope :teams_for_policy, -> () { sender.teams.merge(recipient.teams) }
  end
  def teams  # the obj method returns the instance being regulated
    [obj.sender, obj.recipient, !obj.private? && obj.teams_for_policy]
  end
  regulate_broadcast { |policy| policy.send_all.to(policy.teams) }
end
```

## Regulating Scopes

Consider the following expression (evaluated on the client)

```ruby
  Order.for_vip_customers.count
```

Even though the policy system will prevent us from looking into the actual attributes of any record, a malicioius hacker can find private information about our data if the above expression is not secured.  Moreover a DOS attack could be formed by repeatedly attempting to perform a variant of `Order.all`.

To prevent this scopes and relationships can also be regulated.   A scope and relationship regulation is a proc that will return either a truthy or falsy value or calls the `denied!` method.   The proc is evaluated in the context of the relationship object, and the `acting_user` method is available for the proc's use in making decisions.

All the scopes in a chain are evaluated together, and permission is granted or denied as follows:

+ If *any* of the regulations in a chain of scopes calls `denied!` then the remote request is aborted;
+ If *any* of the regulations in a chain of scopes returns a truthy value then access is granted to the entire chain;
+ If *none* of the regulations in a chain of scopes returns a truthy value then the request is aborted.

Example:

```ruby
class Order < ApplicationRecord
  regulate_scope(:for_vip_customers) { denied! unless acting_user.admin? }
  regulate_scope(:active) { acting_user.admin? } 
end

class User < ApplicationRecord 
  regulate_relationship(:orders) { self == acting_user }
end

 # in component code
 
   user.orders.count              # valid if user is the acting user because the orders regulation returned true
                                  # but will raise error if acting_user is not == user
   user.orders.active.count       # valid if user is the acting user or if current user is an administrator
   user.orders.for_vip_customers  # fails unless acting user is an admin
```

By default all relationships and scopes (including `all` and `unscoped` have a regulation that returns nil, so unless you explicitly provide a regulation that returns true, the client can not access any scopes.

There are some short hand ways to define regulations as well:

#### Constant Regulations

If the regulation always does the same thing you can specify what to do without the block:

```ruby
  regulate_scope my_scope: :always_allow        # any truthy value works
  regulate_scope my_scope: :denied!             # :deny or :denied work as well
  regulate_relationship many_of_those: :denied! # works the same on relationships
```

Always denying a regulation effectively makes it inaccessible except on the server.

Likewise be careful of always returning true for a scope, as this means that a hacker only needs
to include this scope in the chain to gain access to the chain.  So just make sure that scopes that return
true, narrow the scope down to something you would not mind anybody seeing.

For development you can easily access everything (except regulations that explicitly invoke denied!) simply by doing this:

```ruby
class ApplicationRecord < ActiveRecord::Base
  regulate_scope all: :always_allow if Rails.env.development?
  regulate_scope unscoped: :always_allow if Rails.env.development?
end
```

#### Regulations directly on scopes and has_many relationships

You can also directly add the regulation where you declare the scope or relationship using the `regulate:` option.

```ruby
  # here is a handy scope to add to ApplicationRecord that you can attach to 
  # any scope chain to give admin's full access
  scope :admin, ->() {}, regulate: -> () { acting_user.admin? || denied! }
  
  # customers can always see their orders, otherwise we return nil meaning "don't know yet"
  has_many :orders, regulate: -> () { acting_user == self } 
```

## Regulating server_method and finder_method methods

The server or finder method proc will be executed in the context of the appropriate object (a record for server_method, and a relationship collection for finder_method.) Attached to this object will be the current `acting_user` method, and a `denied!` method.

You can use these methods to restrict access to server and finder methods.

```ruby
  server_method :unit_cost do
    denied! unless acting_user.admin? # only admin's can see this
    # continue on calculating the unit cost
  end
```

## Browser Initiated Change policies

To allow code in the browser to create, update or destroy a model, there must be a change access policy defined for that operation.

Each change access policy executes a block in the context of the record that will be accessed.  The current value of `acting_user` is also defined for the life of the block.

If the block returns a truthy value access will be allowed, otherwise if the block returns a falsy value or raises an exception, access will be denied.

In the below examples we assume that your user model responds to `admin?` but this is not built into Hyperloop.

```ruby
class TodoPolicy
  # allow creation to any logged in user
  allow_create { acting_user }
  # only allow the owner, author any any admin to update a todo
  allow_update { acting_user == owner || acting_user == author || acting_user.admin? }
  # don't allow Todo's to be destroyed
  # this is the default behavior so its not actually needed
  allow_destroy { false }
end
```

There are several variants of the access policy method:

```ruby
class ConfigDataPolicy
  allow_change(on: [:create, :update, :destroy]) { acting_user.admin? }
  # which can be shortened to:
  allow_change { acting_user.admin? }
end
```

```ruby
class ApplicationPolicy
  # do any thing to all models unless we are in production!  Be careful!
  allow_change(to: :all) { true } unless Rails.env.production?
  # and always allow admins to destroy models globally:
  allow_change(to: :all, on: :destroy) { acting_user.admin? }
  # which is the same as saying:
  allow_destroy(to: :all) { acting_user.admin? }
  # you can create model specific policies in the Application Policy as well.
  # Here we allow the author of a message to destroy the message within 5
  # minutes of creation.
  allow_destroy(to: Message) do
    return true if acting_user == author && created_at > 5.minutes.ago
    return true if acting_user.admin?
  end
end
```

Note that there is no `allow_read` method.  Read access is granted if this browser would have the attribute broadcast to it.  

## Method Summary and Name Space Conflicts

Policy classes (and the Hyperloop::PolicyMethods module) define the following class methods:

+ `regulate_connection`
+ `regulate_all_broadcasts`
+ `regulate_broadcast`

As well as the following instance methods:
+ `send_all`
+ `send_all_but`
+ `send_only`
+ `obj`

To avoid name space conflicts with your classes, Hyperloop policy classes (and the Hyperloop::PolicyMethods module) maintain class and instance `attr_accessor`s named `synchromesh_internal_policy_object`.   The above methods call methods of the same name in the appropriate internal policy object.

You may thus freely redefine of the class and instance methods if you have name space conflicts

```ruby
class ProductionCenterPolicy < MyPolicyClass
  # MyPolicyClass already defines our version of obj
  # so we will call it 'this'
  def this
    synchromesh_internal_policy_object.obj
  end
  ...
end
```  
