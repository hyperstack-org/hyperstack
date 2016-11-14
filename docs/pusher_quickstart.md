### Pusher Configuration

Add `gem 'pusher'` to your gem file, and add `//= require 'HyperMesh/pusher'` to your application.js file.

```ruby
# typically config/initializers/HyperMesh.rb
HyperMesh.configuration do |config|
  config.transport = :pusher
  config.opts = {
    app_id: '2xxxx2',
    key:    'dxxxxxxxxxxxxxxxxxx9',
    secret: '2xxxxxxxxxxxxxxxxxx2',
    encrypted: false # optional defaults to true
  }
  config.channel_prefix = 'syncromesh' # or any other string you want
end
```
