# hyper-transport-pusher
Driver for Pusher.com pub sub service for hyper-transport for hyperstack.

# Installation
get from repo

# Config

in your frameworks config or initializer:

```ruby
    Hyperstack.pusher_options = {} # options for the Pusher client on the client to use
    Hyperstack.pusher_server_options = {} # options for the pusher client on the server to use
    
    # that gets set automatically if you include this gem:
    Hyperstack.server_pub_sub_driver = Hyperstack::Transport::Pusher::ServerDriver
```