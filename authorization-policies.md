### Synchromesh Authorization Policies

Each time an ActiveRecord model changes, Synchromesh broadcasts the changed attributes over *channels*.

An application can have several channels and each channel and each active record model can have different policies to determine which attributes are sent when a record changes.

For example a Todo application might have an *instance* of a channel for each specific logged in user, an instance of a channel for each specific team for any team that has one or more logged in users, and an general `AdminUser` channel shared by all administrators that are logged in.

Lets say a specific `Todo` changes, which is part of team id 123's Todo list, and users 7, and 8 who are members of that team are currently logged in as well as two of the `AdminUsers`.  

When the `Todo` changes we want all the attributes of the `Todo` broadcast on `Team` 123's channel, as well on the `AdminUser`'s channel.  Now lets say User 7, sends User 8 a private message, adding a new record to the `Message` model.  This update should only be sent to the user 7 and user 8's private channel, as well as to the AdminUser channel.

We can define all these policies by creating the following classes:

```ruby
class UserPolicy # defines policies for the User class
  # The connection_policy method enables the User class to be treated
  # as a channel.  

  # To establish the connection the acting_user's id must
  # equal the instance id of the channel
  connection_policy do |acting_user, channel_instance_id|
    acting_user.id == channel_instance_id
  end
end

class TeamPolicy # defines policies for the Team class  
  # Users can only connect to Team channels that they are the members of
  connection_policy do |acting_user, channel_instance_id|
    Team.find(channel_instance_id).members.include? acting_user
  end
end

class AdminUserPolicy
  # All AdminUser's share the same connection so we do not check the
  # channel instance_id
  connection_policy do |acting_user|
    acting_user.try(:admin?)
  end

  # For the AdminUser channel we want to receive all attributes
  # of all records, unless the attribute is named :password
  channel_broadcast_policy do |transport|
    transport.send_all_but(:password)
  end
end

class TodoPolicy
  # Policies can be established for models that are not channels as well.

  # The instance_broadcast_policy will describe what attributes to send when a
  # todo model changes.  

  # The policies' block executes in the context of the changed model
  # so we have access to all the models methods.  In this case Todo
  # belongs to a Team through the 'team' relationship.
  instance_broadcast_policy do |transport|
    # send all Todo attributes to the specific team channel
    transport.send_all.to(team)
  end
end

class MessagePolicy
  # Broadcast policies can be arbitrarily complex.  In this case we
  # want to broadcast the entire message to the sender and the
  # recipient's instance channels (if they are open.)  
  # In addition if the message is not private, then we want to send to all
  # the team instance channels that are shared between the sender and
  # recipient's teams.
  instance_broadcast_policy do |transport|
    transport.send_all.to(sender, recipient)
    transport.send_all.to(sender.teams.merge(recipient.teams)) unless private?
  end
end
```

Before we begin using these channels and policies we need to first define the `acting_user` method in our ApplicationController:

```ruby
class ApplicationController < ActiveController::Base
  def acting_user
    # The acting_user method should return nil, or some object that corresponds to a
    # logged in user.  Specifics will depend on your application and whatever other
    # authentication mechanisms you are using.
    @acting_user ||= session[:current_user_id] && User.find_by_id(session[:current_user_id])
    end
  end
end
```

Note that `acting_user` is also used by `reactive-record`'s permission system.

Finally on the client side we connect to our Channels using the `Synchromesh.connect` method:

```ruby
# Assume we have logged in there is a variable or method current_user
# that returns the current_user User model.
# Likewise there is a team method or variable that returns a team object
# that the current_user belongs to.

# connect to team's channel instance
Synchromesh.connect(team)
Synchromesh.connect(current_user)

# try connecting to the AdminUser class channel
Synchromesh.connect(AdminUser) # fails unless current_user is an admin
```

Lets walk through what happens as the code runs:

1. Client side code does a `Synchromesh.connect(team)`
2. The server receives the request to connect to the Team channel with the id of the team instance.
3. The `Team` connection policy will be passed the current user, and the Team's id.
4. Assuming the connection is allowed, the client will start receiving broadcasts on the team's instance channel.
5. A `Todo` now changes
6. All open channels will execute their `broadcast_policy` methods.  
7. The `broadcast_policy` for the Todo model is executed.
8. Each channel receives a (possibly) filtered version of the changed record as specified by the `transport.send...` commands.  

### Details

#### Defining Policies and Policy Classes

The best way to define policies is to use a Policy Class.  A policy class has the same class name as the class it is defining policies for, with `Policy` added to the end.  Policy classes are compatible with `Pundit`, and you can add regular pundit policies as well.

By convention policy classes go in the `app/policies` directory

If you wish, you can also specify policies directly in your models, by including the `Synchromesh::PolicyMethods` module in your model.  You can then use the connection, channel and instance policy methods directly in the model.

```ruby
class User < ActiveRecord::Base
  include Synchromesh::PolicyMethods
  connection_policy { |acting_user, id| acting_user.id == id }
  channel_broadcast_policy ...
  instance_broadcast_policy ...
end
```

Normally the policy methods are applied to the class they are called in, but you can override this by providing the specific class name to the policy method.  THis allows you to group several different class policies together:

```ruby
class ApplicationChannel
  include Synchromesh::PolicyMethods
  # creates the ApplicationChannel connection policy
  connection_policy { ... }  
  # but then list each of the instance broadcast policies here
  instance_broadcast_policy(Todo) { ... }
  instance_broadcast_policy(Message) { ... }
end
```

#### Channels and the `connection_policy` method

Any ruby class that has a connection policy is a synchromesh channel. The fully scoped name of the class becomes the root of the channel name.

The purpose of having channels is to restrict what gets broadcast when models change, therefore typically channels represent *connections* to

+ the application, or some function within the application
+ or some class which *logs in* like a User or Administrator,
+ or instances of those classes.

So a channel that is connected to the User class would get information readable by any logged-in user, while a channel that is connected to a specific User instance would get information readable by that specific user.

Whether a channel can represent a connection to the class, an instance or both is specified by the connection policy.  The first argument to the policy is the `acting_user`, and the second argument (if present) is the id of the instance being connected to, or nil if connecting to the class.

If the connection policy block takes zero or one arguments then clients can only connect to the class, and attempt to connect to an instance will fail.

If the connection policy expects to connect to both an instance and the class then it needs to accept the second parameter, which will either be the id of the instance, or nil if it connecting to the class channel.

Keep in mind the connection_policy is a safety check.  Your client code should not be attempting to
connect on a channel that will fail.  Failed connections are treated as security violations and
are not designed to be recoverable.  Therefore the connection policy can fail either by returning a falsy value or raising an error.

```ruby
# create a class connection only if the acting_user is non-nil (i.e. logged in)
connection_policy { |acting_user| acting_user }
# always open the connection
connection_policy { |acting_user| true }
# which can be shortened to
connection_policy { true }
# create a class level connection if the acting_user is an admin
connection_policy { |acting_user| acting_user.admin? }
# create an instance connection for the current user
connection_policy { |acting_user, id| acting_user.id == id }
# allow both instance and class connections
connection_policy { |acting_user, id| acting_user && (id.nil? || acting_user.id == id)}
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
4. and call the channel's `connection_policy`.
5. If true is returned the channel is established,
6. otherwise a 500 error is returned.

#### Disconnecting

Calling `Synchromesh.disconnect(channel)` will disconnect from the channel.

#### Broadcasting and Broadcast Policies

Broadcast policies can be defined for channels using the `channel_broadcast_policy` method, and for individual objects (typically ActiveRecord models) using the `instance_broadcast_policy`.  

After an ActiveRecord model change is committed, all active class channels execute their channel broadcast policies, and then the instance broadcast policy associated with the changing model is executed.  So for any change there may be multiple channel broadcast policies involved, but only one (at most) instance_broadcast_policy.  

The result is that each channel may get a filtered copy of the record which is broadcast on that channel.

The purpose of the policies then is to determine which channel sees what.  Each policy receives a transport object that responds to the following methods

+ `send_all`: send all the attributes of the record.
+ `send_only`: send only the listed attributes of the record.
+ `send_all_but`: send all the attributes execpt the ones listed.

The result of the `send...` method is then directed to set of channels using the `to` method:

```ruby
transport.send_all_but(:password).to(AdminUser)
```

Within channel broadcast policies the channel is assumed to be the channel in question:

```ruby
class AdminUserPolicy
  channel_broadcast_policy do |transport|
    transport.send_all_but(:password) #.to(AdminUser) is not needed.
  end
end
```

The `to` method can take any number of arguments:

+ a class naming a channel,
+ an object that is instance channel,
+ or an array (or ActiveRecord collection) of objects representing instance channels.

The instance broadcast policy executes in the context of the model that has just changed, so it can use all the methods of that model, especially relationships.  For example:

```ruby
class Message < ActiveRecord::Base
  include Synchromesh::PolicyMethods
  belongs_to :sender, class: "User"
  belongs_to :recipient, class: "User"
  instance_broadcast_policy do |transport|
    # send all attributes to both the sender, and recipient User instance channels
    transport.send_all.to(sender, recipient)
    # send all attributes to intersection
    transport.send_all.to(sender.teams.merge(recipient.teams)) unless private?
  end
end
```

It is possible that the same channel may be sent a record from different policies, in this case the minimum set of attributes will be sent regardless of the order of the send operations.  For example:

```ruby
transport.send_all_but(:password).to(MyChannel)
# ... later
transport.send_all.to(MyChannel)
# MyChannel gets everything but the password
```

or even

```ruby
transport.send_only(:foo, :bar).to(MyChannel)
transport.send_only(:baz).to(MyChannel)
# MyChannel gets nothing
```
