### HyperMesh Authorization Policies

Each time an ActiveRecord model changes, HyperMesh broadcasts the changed attributes over *channels*.

An application can have several channels and each channel and each active record model can have different *policies* to determine which attributes are sent when a record changes.

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

  # For our User instance connection the policy is that there must be logged in
  # user, and the connection is made to that user:
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

Note that `acting_user` is also used by Reactive-Record's permission system.

Our entire set of policies is defined in 29 lines of code of which 8 actually execute the policies.  Our existing classes form the foundation, and we simply add synchromesh specific policy directives.  Pretty sweet huh?

### Details

HyperMesh uses *Policies* to *regulate* what *connections* are opened between clients and the server and what data is distributed over those connections.

Connections are made on *channels* of data flowing between the server and a number of clients.  Each channel is associated with either a class or an instance of a class.  Typically the channel class represents an entity (or is associated with an entity) that can be authenticated like a `User`, an  `AdminUser`, or a `Team` of users.  A channel associated with the class itself broadcasts data that is received by any member of that class.  A channel associated with an instance is for data that is available only to that specific instance.   

As models on the server change (i.e. created, updated, or destroyed) the changes are broadcast over open channels.  What specific attributes are sent (if any) is determined by broadcast policies.

Broadcast policies can be associated with models.  As the model changes the broadcast policy will regulate what attributes of the changed model will be sent over which channels.  

Broadcast policies can also be associated with a channel and will regulate *all* model changes over specific channels.  In other words this is just a convenient way to associate a common policy with *all* models.

Note that models that are associated with channels can also broadcast their changes on the same or different channels.

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

Note that by default policy classes go in the `app/policies` directory.  HyperMesh will require all the files in this directory.

If you wish, you can also add policies directly in your models by including the `HyperMesh::PolicyMethods` module in your model.  You can then use the `regulate_class_connection`, `regulate_instance_connections`, `regulate_all_broadcasts` and `regulate_broadcast` methods directly in the model.

```ruby
class User < ActiveRecord::Base
  include HyperMesh::PolicyMethods
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

#### Channels and the connection policies

Any ruby class that has a connection policy is a synchromesh channel. The fully scoped name of the class becomes the root of the channel name.

The purpose of having channels is to restrict what gets broadcast when models change, therefore typically channels represent *connections* to

+ the application, or some function within the application
+ or some class which *authenticated* like a User or Administrator,
+ instances of those classes,
+ or instances of related classes.

So a channel that is connected to the User class would get information readable by any logged-in user, while a channel that is connected to a specific User instance would get information readable by that specific user.

The `regulate_class_connection` takes a block that will execute in the context of the current acting_user (which may be nil), and if the block returns any truthy value, the connection will be made.

The `regulate_instance_connections` likewise takes a block that is executed in the context of the current acting_user.  The block may do one of following:

+ raise an error meaning the connection cannot be made,
+ return a falsy value also meaning the connection cannot be made,
+ return a single object meaning the connection can be made to that object,
+ return a enumerable of objects meaning the connection can made to any member of the enumerable.

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

#### Class Names, Instances and Ids

While establishing connections, classes are represented as their fully scoped name, and instances are represented as the class name plus the result of calling `id` on the instance.

Typically connections are made to ActiveRecord models, and if those are in the `app/models/public` folder everything will work fine.

#### Acting User

HyperMesh uses the same `acting_user` method that reactive-record permissions uses.  This method is typically defined in the ApplicationController and would normally pick up the current session user, and return an appropriate object.

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

Its important to consider turning off automatic connections for cases like the above where
the user is likely to be a member of many teams.  Typically the client application will
want to dynamically determine which specific teams to connect to given the current state of
the application.

### Manually Connecting to Channels

Normally the client will automatically connect to the available channels when a page loads, but you can also
manually connect on the client in response to some user action like logging in, or the user deciding to
display a specific team status on their dashboard.

To manually connect a client use the `HyperMesh.connect` method.  

The `connect` method takes any number of arguments each of which is either a class, an object, a String or Array.

If the argument is a class then the connection will be made to the matching class channel on the server.

```ruby
# connect the client to the AdminUser class channel
HyperMesh.connect(AdminUser)
# if the connection is successful the client will begin getting updates on the
# AdminUser class channel
```

If the argument is an object then a connection will be made to the matching object on the server.

```ruby
# assume current_user is an instance of class User
HyperMesh.connect(current_user)
# current_user.id is used to establish which User instance to connect to on the
# server
```

The argument can also be a string, which matches the name of a class on the server

```ruby
HyperMesh.connect('AdminUser')
# same as AdminUser class
```

or the argument can be an array with a string and the id:

```ruby
HyperMesh.connect(['User', current_user.id])
# same as saying current_user
```

You can make several connections at once as well:
```ruby
HyperMesh.connect(AdminUser, current_user)
```

Finally falsy values are ignored.

You can also send `connect` directly to ActiveRecord models:

```ruby
AdminUser.connect!    # same as HyperMesh.connect(AdminUser)
current_user.connect! # same as HyperMesh.connect(current_user)
```

#### Connection Sequence Summary

For class connections:

1. The client calls `HyperMesh.connect`.
2. HyperMesh sends the channel name to the server.
3. HyperMesh has its own controller which will determine the `acting_user`,
4. and call the channel's `regulate_class_connection` method.
5. If `regulate_class_connection` returns a truthy value then the connetion is made,
6. otherwise a 500 error is returned.

For instance connections:

1. The process is the same but the channel name and id are sent to the server.  
2. The HyperMesh controller will do a find of the id passed to get the instance,
3. and if successful `regulate_instance_connections` is called,
4. which must return an either the same instance, or an enumerable with that instance as a member.
5. Otherwise a 500 error is returned.

Note that the same sequence is used for auto connections and manually invoked connections.

#### Disconnecting

Calling `HyperMesh.disconnect(channel)` or `channel.disconnect!` will disconnect from the channel.

#### Broadcasting and Broadcast Policies

Broadcast policies can be defined for channels using the `regulate_all_broadcasts` method, and for individual objects (typically ActiveRecord models) using the `regulate_broadcast` method.  A `regulate_all_broadcasts` policy is essentially a `regulate_broadcast` that will be run for every record that changes in the system.

After an ActiveRecord model change is committed, all active class channels run their channel broadcast policies, and then the instance broadcast policy associated with the changing model is run.  So for any change there may be multiple channel broadcast policies involved, but only one (at most) regulate_broadcast.  

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

Keep in mind that the broadcast policies are sent a copy of the policy object so you can use helper methods in your policies. Also you can add policy specific methods to your models using
`class_eval` thus keeping policy logic out of your models.

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

#### Method Summary and Name Space Conflicts

Policy classes (and the HyperMesh::PolicyMethods module) define the following class methods:

+ `regulate_connection`
+ `regulate_all_broadcasts`
+ `regulate_broadcast`

As well as the following instance methods:
+ `send_all`
+ `send_all_but`
+ `send_only`
+ `obj`

To avoid name space conflicts with your classes, synchromesh policy classes (and the HyperMesh::PolicyMethods module) maintain class and instance `attr_accessor`s named `synchromesh_internal_policy_object`.   The above methods call methods of the same name in the appropriate internal policy object.

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

#### Setting the policy directory

*HyperMesh auto-connect needs to know about all policies ahead of time so cannot rely on rails auto loading.  Sorry about that!*

By default HyperMesh will load all the files in the `app/policies` directory.  To change the directory set the policy_directory in the synchromesh initializer.  

```ruby
HyperMesh.configuration do |config|
  ...
  config.policy_directory = File.join(Rails.root, 'app', 'synchromesh-authorization')
  # can also be set to nil if you want to manually require your files
end
```
