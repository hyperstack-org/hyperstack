# Policies

TODO: THIS PAGE SHOULD BE RE-WRITTEN AS A HIGH LEVEL CONCEPTUAL UNDERSTANDING OF POLOCIES

Hyperstack uses Policies to regulate what connections are opened between clients and the server and what data is distributed over those connections.

### Policy Classes

Policies are defined through policy classes:

```ruby
class UserPolicy # defines policies for the User class
  # The regulate_instance_connections method enables instances of the User
  # class to be treated as a channel.

  # The policy is defined by a block that is executed in the context of the
  # current acting_user.

  # For our User instance connection the policy is that there must be a
  # logged-in user and the connection is made to that user:
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
  # so we have access to all the model's methods.  In this case Todo
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

--------------------------

That concludes this introduction to Hyperloop, but before you go on to our Tutorials or Docs, please read the next section where we describe our pragmatic approach to architecture.
