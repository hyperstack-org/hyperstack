# hyper-transport-store-redis
A subscription store for hyper-transport

## Installation

get from repo

## Configuration

in your frameworks config or initializer: 

```ruby
  # thats set by default
  Hyperstack.server_subscription_store = Hyperstack::Transport::SubscriptionStore::Redis
  
  # that can be adjusted to the options Redis would usually accept
  Hyperstack.redis_options = {}
```
