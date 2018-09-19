# Temporary Install Instructions
----
Currently the entire hyperstack repo structure is being rebuilt, CI testing is being added, etc, etc.   So right now you have
pull the gems from this github branch.

This will be resolved very shortly after which simply adding the `Hyperloop` (and eventually `Hyperstack`) gem to your Gemfile
will be all that is needed.

Sorry for the inconvience

----------

1.  In a new or existing rails app add  

```ruby
gem 'hyperloop', github: 'hyperstack-org/hyperstack', branch: 'hyperloop-legacy', glob: 'ruby/*/*.gemspec'
```

2. Bundle install
3. Add the hyperloop stuff: `bundle exec rails g hyperloop:install`
4. Fire it up: `bundle exec foreman start` (this starts the server and a hot reloader watcher process)
5. checkout `localhost:5000` and you should see **App** displayed.
6. get `opal-hot-reloader` from hyperstack repo:  
There is an incompatibility with the current `opal-hot-reloader` and the latest hyperloop gems.  So once everything else is
working find  
```ruby
  gem 'opal-hot-reloader'
```  
  towards the bottom of the Gemfile, and replace it with 
```ruby
gem 'opal_hot_reloader', github: 'hyperstack-org/opal-hot-reloader'
```

7. restart foreman

Now if you try editing your App file you will find the hot reloader faithfully updates the display (or shows a runtime error
message) after each save.


