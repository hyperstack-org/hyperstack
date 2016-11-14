## Installation

If you do not already have hyper-react installed, then use the reactrb-rails-generator gem to setup hyper-react, reactive-record and associated gems.

Then add this line to your application's Gemfile:

```ruby
gem 'HyperMesh'
```

And then execute:

    $ bundle install

Also you must `require 'hyper-tracemesh'` from your client side code.  The easiest way is to
find the `require 'reactive-record'` line (typically in `components.rb`) and replace it with
 `require 'HyperMesh'`.  

## Configuration

Add an initializer like this:

```ruby
# for rails this would go in: config/initializers/HyperMesh.rb
HyperMesh.configuration do |config|
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

Assuming you are up and running with Hyper-React on Rails:

1. **Add the gem**  
add `gem 'hyper-mesh'`, and bundle install
6. **Add the models directory to asset path**   
```ruby
# application.rb
    config.assets.paths << ::Rails.root.join('app', 'models').to_s
```

2. **Require HyperMesh instead of HyperReact**  
replace `require 'hyper-react'` with `require 'hyper-mesh'` in the components manifest (`app/views/components.rb`.)
3. **Require your models on the client_side_scoping**  
add `require 'models'` to the bottom of the components manifest
4. add a models manifest in the models directory:  
```ruby
# app/models/models.rb
require_tree './public'
```
5. create a `public` directory in your models directory and move any models that you want access to on the client into this directory.  Access to these models will be protected by *Policies* you will be creating later.

A minimal HyperMesh configuration consists of a simple initializer file, and at least one *Policy* class that will *authorize* who gets to see what.

The initializer file specifies what transport will be used.  Currently you can use [Pusher](http://pusher.com), ActionCable (if using Rails 5), Pusher-Fake (for development) or a Simple Poller for testing etc.
