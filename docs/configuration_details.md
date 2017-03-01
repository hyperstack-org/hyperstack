# Hyperloop Configuration

TODO will this be replaced by readme from hyper-configuration gem?

There are parts to the Hyperloop configuration:

1. Model classes
2. Policies
3. Push Transport

## Configuration

Add an initializer like this:

```ruby
# for rails this would go in: config/initializers/Hyperloop.rb
Hyperloop.configuration do |config|
  config.transport = :simple_poller # or :none, action_cable, :pusher - see below)
end
# for a minimal setup you will need to define at least one channel, which you can do
# in the same file as your initializer.
# Normally you would put these policies in the app/policies/ directory
class ApplicationPolicy
  # allow all clients to connect to the Application channel
  regulate_connection { true } # or always_allow_connection for short
  # broadcast all model changes over the Application channel *DANGEROUS*
  regulate_all_broadcasts { |policy| policy.send_all }
end
```

A minimal Hyperloop configuration consists of a simple initializer file, and at least one *Policy* class that will *authorize* who gets to see what.

The initializer file specifies what transport will be used.  Currently you can use [Pusher](http://pusher.com), ActionCable (if using Rails 5), Pusher-Fake (for development) or a Simple Poller for testing etc.
