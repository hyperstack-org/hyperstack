### Synchromesh Authorization Policies

Each time an ActiveRecord model changes, Synchromesh broadcasts the changed attributes over *channels*.

An application can have several channels and each channel and each active record model can have different policies to determine which attributes are sent when a record changes.

For example a Todo application might have an *instance* of a channel for each specific logged in user, an instance of a channel for each specific team for any team that has one or more logged in users, and a general `AdminUser` channel shared by all administrators that are logged in.

Lets say a specific `Todo` changes, which is part of team id 123's Todo list, and users 7 and 8 who are members of that team are currently logged in as well as two of the `AdminUsers`.  

When the `Todo` changes we want all the attributes of the `Todo` broadcast on `Team` 123's channel, as well on the `AdminUser`'s channel.  Now lets say User 7 sends User 8 a private message, adding a new record to the `Message` model.  This update should only be sent to the user 7 and user 8's private channel, as well as to the AdminUser channel.

We can define all these policies by creating the following classes:

```ruby
class UserPolicy # defines policies for the User class
  include Synchromesh::PolicyMethods
  # The regulate_connection method enables the User class to be treated
  # as a channel.  

  # To establish the connection the acting_user's id must
  # equal the instance id of the channel
  regulate_connection do |acting_user, channel_instance_id|
    acting_user.id == channel_instance_id
  end
end

class TeamPolicy # defines policies for the Team class  
  include Synchromesh::PolicyMethods
  # Users can only connect to Team channels that they are the members of
  regulate_connection do |acting_user, channel_instance_id|
    Team.find(channel_instance_id).members.include? acting_user
  end
end

class AdminUserPolicy
  include Synchromesh::PolicyMethods
  # All AdminUser's share the same connection so we do not check the
  # channel instance_id
  regulate_connection do |acting_user|
    acting_user.admin?
  end

  # For the AdminUser channel we want to receive all attributes
  # of all records, unless the attribute is named :password
  regulate_all_broadcasts do |policy|
    policy.send_all_but(:password)
  end
end

class TodoPolicy
  include Synchromesh::PolicyMethods
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
  include Synchromesh::PolicyMethods
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

Finally on the client side we connect to our channels using the `Synchromesh.connect` method:

```ruby
# Assume we have logged in and there is a variable or method current_user
# that returns the current_user User model.

# Likewise there is a team method or variable that returns a team object
# that the current_user belongs to.

# connect to team's channel instance
Synchromesh.connect(team)
Synchromesh.connect(current_user)

# connect to the AdminUser class channel if user is an admin
Synchromesh.connect(AdminUser) if current_user.admin?
```

Lets walk through what happens as the code runs:

1. Client side code does a `Synchromesh.connect(team)`
2. The server receives the request to connect to the Team channel with the id of the team instance.
3. The `Team` connection policy will be passed the current user, and the Team's id.
4. Assuming the connection is allowed, the client will start receiving broadcasts on the team's instance channel.
5. A `Todo` now changes
6. All open channels will any `regulate_all_broadcasts` policies they have defined.  
7. The `regulate_broadcast` policy for the Todo model is run.
8. Each channel receives a (possibly) filtered version of the changed record as defined by the policies.

### Details

Synchromesh uses *Policies* to *regulate* what *connections* are opened between clients and the server and what data is distributed over those connections.

Connections are made on *channels* of data flowing between the server and a number of clients.  Each channel is associated with either a class or an instance of a class.  Typically the class represents an entity that can be authenticated like a `User` or an `AdminUser`.  A channel associated with the class itself will broadcast data that is received by any member of that class.  A channel associated with an instance is for data that is available only to that specific instance.   

As models on the server change (i.e. created, updated, or destroyed) the changes are broadcast over open channels.  What specific attributes are sent (if any) is determined by broadcast policies.

Broadcast policies can be associated with models.  As the model changes the broadcast policy will regulate what attributes of the changed model will be sent over which channels.  

Broadcast policies can also be associated with a channel and will regulate *all* model changes over specific channels.  In other words this is just a convenient way to associate a common policy with *all* models.

Note that models can be associated with channels can also broadcast their changes of the same or different channels.

#### Defining Policies and Policy Classes

The best way to define policies is to use a *Policy Class*.  A policy class has the same class name as the class it is regulating, with `Policy` added to the end.  Policy classes are compatible with `Pundit`, and you can add regular pundit policies as well.

Policies are defined using three methods:
+ `regulate_connection` controls connections to the classes, or instances of classes,
+ `regulate_broadcast` controls what data will be sent when a model or object changes and,
+ `regulate_all_broadcasts` controls what data will be sent of some channels when any model changes.

If a policy class is defined for which there is no regulated class, the class will be created for you.  This is useful for application wide connections, which are typically open even if no one is logged in:

```ruby
#app/policies/application.rb
class ApplicationPolicy
  include Synchromesh::PolicyMethods
  regulate_connection { true }
end
```

Note that by convention policy classes go in the `app/policies` directory.

If you wish, you can also add policies directly in your models by including the `Synchromesh::PolicyMethods` module in your model.  You can then use the `regulate_connection`, `regulate_all_broadcasts` and `regulate_broadcast` methods directly in the model.

```ruby
class User < ActiveRecord::Base
  include Synchromesh::PolicyMethods
  regulate_connection ...
  regulate_all_broadcasts ...  
  regulate_broadcast ...
end
```

Normally the policy methods are regulating the class with the prefix as the policy, but you can override this by providing specific class names to the policy method.  This allows you to group several different class policies together, and to reuse policies:

```ruby
class ApplicationPolicy
  include Synchromesh::PolicyMethods
  regulate_connection { ... }  # Application is assumed
  regulate_connection(User) { ... }
  # regulate_connection and regulate_all_broadcasts can take
  # a list of channels.
  regulate_all_broadcasts(User, Application)
  # regulate_broadcast takes a list of object classes which
  # may also be channels.
  regulate_broadcast(Todo, Message, User) { ... }
end
```

#### Channels and the `regulate_connection` method

Any ruby class that has a connection policy is a synchromesh channel. The fully scoped name of the class becomes the root of the channel name.

The purpose of having channels is to restrict what gets broadcast when models change, therefore typically channels represent *connections* to

+ the application, or some function within the application
+ or some class which *logs in* like a User or Administrator,
+ or instances of those classes.

So a channel that is connected to the User class would get information readable by any logged-in user, while a channel that is connected to a specific User instance would get information readable by that specific user.

Whether a channel can represent a connection to the class, an instance or both is determined by the connection policy.  The first argument to the policy is the `acting_user`, and the second argument (if present) is the id of the instance being connected to, or nil if connecting to the class.

If the connection policy block takes only one or no arguments then clients can only connect to the class, and an attempt to connect to an instance will fail.

If the connection policy expects to connect to both an instance and the class then it needs to accept the second parameter, which will either be the id of the instance, or nil if it connecting to the class channel.

Keep in mind the connection policy is a safety check.  Your client code should not be attempting to
connect on a channel that will fail.  Failed connections are treated as security violations and
are not designed to be recoverable.  Therefore the connection policy can fail either by returning a falsy value or raising an error.

```ruby
# create a class connection only if the acting_user is non-nil (i.e. logged in)
regulate_connection { |acting_user| acting_user }
# always open the connection
regulate_connection { |acting_user| true }
# which can be shortened to
regulate_connection { true }
# create a class level connection if the acting_user is an admin
regulate_connection { |acting_user| acting_user.admin? }
# create an instance connection for the current user
regulate_connection { |acting_user, id| acting_user.id == id }
# allow both instance and class connections
regulate_connection { |acting_user, id| acting_user && (id.nil? || acting_user.id == id)}
```

#### Class Names, Instances and Ids

While establishing connections, classes are represented as their fully scoped name, and instances are represented as the class name plus the result of calling 'id' on the instance.

Typically connections are made to ActiveRecord models, and if those are in the `app/models/public` folder everything will work fine.  If necessary there are mechanisms on the client side to deal with special cases.

#### Acting User

Synchromesh uses the same `acting_user` method that reactive-record permissions uses.  This method is typically defined in the ApplicationController and would normally pick up the current session user, and return an appropriate object.

```ruby
class ApplicationController < ActiveController::Base
  def acting_user
    @acting_user ||= session[:current_user_id] && User.find_by_id(session[:current_user_id])
    end
  end
end
```

### Connecting to Channels

Within your Reactrb code you connect to the channels using the `Synchromesh.connect` method.

The `connect` method takes any number of arguments each of which is either a class, an object, a String or Array.

If the argument is a class then the connection will be made to the matching class channel on the server.

```ruby
# connect to the AdminUser class channel
Synchromesh.connect(AdminUser)
# if the connection is successful the client will begin getting updates on the
# AdminUser class channel
```

If the argument is an object then a connection will be made to the matching object on the server.

```ruby
# assume current_user is an instance of class User
Synchromesh.connect(current_user)
# current_user.id is used to establish which User instance to connect to on the
# server
```

The argument can also be a string, which match the name of a class on the server

```ruby
Synchromesh.connect('AdminUser')
# same as AdminUser class
```

or the argument can be an array with a string and the id:

```ruby
Synchromesh.connect(['User', current_user.id])
# same as saying current_user
```

You can make several connections at once as well:
```ruby
Synchromesh.connect(AdminUser, current_user)
```

Finally falsy values are ignored.

Typically you are going to make connections in your top level application component when a page loads:

```ruby
module Components
  class App < React::Component::Base
    param :current_user, type: User
    after_mount do
      Synchromesh.connect(current_user)
      Synchromesh.connect(AdminUser) if current_user && current_user.admin?
    end
    ...
  end
end
```

#### Connection Sequence

1. Some place on the client `Synchromesh.connect` is called.
2. Synchromesh sends the channel name and possibly object id to the server.
3. Synchromesh has its own controller which will get the `acting_user`,
4. and call the channel's `regulate_connection`.
5. If true is returned the channel is established,
6. otherwise a 500 error is returned.

#### Disconnecting

Calling `Synchromesh.disconnect(channel)` will disconnect from the channel.

#### Broadcasting and Broadcast Policies

Broadcast policies can be defined for channels using the `regulate_all_broadcasts` method, and for individual objects (typically ActiveRecord models) using the `regulate_broadcast`.  A regulate_all_broadcasts is essentially an regulate_broadcast that will be run for every record that changes in the system.

After an ActiveRecord model change is committed, all active class channels run their channel broadcast policies, and then the instance broadcast policy associated with the changing model is run.  So for any change there may be multiple channel broadcast policies involved, but only one (at most) regulate_broadcast.  

The result is that each channel may get a filtered copy of the record which is broadcast on that channel.

The purpose of the policies then is to determine which channel sees what.  Each broadcast policy receives the instance of the policy which responds to the following methods

+ `send_all`: send all the attributes of the record.
+ `send_only`: send only the listed attributes of the record.
+ `send_all_but`: send all the attributes execpt the ones listed.

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

Keep in mind that the broadcast policies are sent a copy of the policy object so you have define helper methods in your policies. Also you can add policy specific methods to your models using
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

Policy classes (and the Synchromesh::PolicyMethods module) define the following class methods:

+ `regulate_connection`
+ `regulate_all_broadcasts`
+ `regulate_broadcast`

As well as the following instance methods:
+ `send_all`
+ `send_all_but`
+ `send_only`
+ `obj`

To avoid name space conflicts with your classes, synchromesh policy classes (and the Synchromesh::PolicyMethods module) maintain class and instance `attr_accessor`s named `synchromesh_internal_policy_object`.   The above methods call methods of the same name in the appropriate internal policy object.

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
