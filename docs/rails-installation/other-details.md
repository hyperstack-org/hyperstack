## Other Rails Configuration Details

Hyperstack sets a number of Rails configurations as outlined below.  

>These are all setup
automatically by the hyperstack generators and installers. They are documented here for advanced configuration or in the sad chance that something gets broken during your setup.  Please report any issues with setup, or if you feel you have to manually tweak things.

#### Require the `hyperstack-loader`

The `app/assets/javascripts/application.js` file needs to require the hyperstack-loader.

```javascript
//= require hyperstack-loader // add as the last require directive
```

The loader handles bringing in client side code, getting it compiled (using sprockets) and adding it to the webpacks (if using webpacker.)

> Note that now that Rails is using webpacker by default you may have to create
this file, and the single line above.  If so be sure to checkout your layout
file, as the javascript_include_tag will also be missing there.

#### `app/assets/config/manifest.js`

If you are using webpacker this file must exist and contain the following line:

```Ruby
//= link_directory ../javascripts .js
```

This line insures that the any javascript in the assets directory are included in the webpacks.  In older versions of Rails, this line will already be there, and if not
using webpacker its actually not necessary (but doesn't hurt anything.)

#### The application layout

If using a recent version of rails with webpacker you may find that the application.html.erb file longer loads the application.js file.  Make sure that your layout file has this line:

```html
   <%= javascript_include_tag 'application' %>
```

#### Required NPM modules

If using Webpacker Hyperstack needs the following NPM modules:

```
yarn 'react', '16'
yarn 'react-dom', '16'
yarn 'react-router', '^5.0.0'
yarn 'react-router-dom', '^5.0.0'
yarn 'react_ujs', '^2.5.0'
yarn 'jquery', '^3.4.1'   # this is only needed if using jquery
yarn 'create-react-class'
```

#### Routing

If using hyper-model you need to mount the Hyperstack engine in the routes file like this:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # this route should be first in the routes file so it always matches'
  mount Hyperstack::Engine => '/hyperstack' # you can use any path you choose
  ...
```

To directly route from a URL to a component you can use the builting Hyperstack
controller with a route like this:

```ruby
  get "hyperstack-page/(*others)", "hyperstack#comp_name"
```

Where `comp_name` is the underscored name of the component you want to mount.  I.e. `MyComp` becomes `my_comp`.  The `/(*others)` indicates that all routes beginning with
`hyperstack-page/` will be matched, if that is your desired behavior.

> Note that the engine mount point can be any string you wish but the controller routed to above is always `hyperstack`.

#### Other Rails Configuration Settings

Hyperstack will by default set a number of Rails configuration settings.  To disable this
set
```ruby
  config.hyperstack.auto_config = false
```
In your Rails application.rb configuration file.

Otherwise the following settings are automatically applied in test and staging:

```ruby
# This will prevent any data transmitted by HyperOperation from appearing in logs
config.filter_parameters << :hyperstack_secured_json

# Add the hyperstack directories
config.eager_load_paths += %W(#{config.root}/app/hyperstack/models)
config.eager_load_paths += %W(#{config.root}/app/hyperstack/models/concerns)
config.eager_load_paths += %W(#{config.root}/app/hyperstack/operations)
config.eager_load_paths += %W(#{config.root}/app/hyperstack/shared)

# But remove the outer hyperstack directory so rails doesn't try to load its
# contents directly
delete_first config.eager_load_paths, "#{config.root}/app/hyperstack"
```
but in production we autoload instead of eager load.
```ruby
  # add the hyperstack directories to the auto load paths
  config.autoload_paths += %W(#{config.root}/app/hyperstack/models)
  config.autoload_paths += %W(#{config.root}/app/hyperstack/models/concerns)
  config.autoload_paths += %W(#{config.root}/app/hyperstack/operations)
  config.autoload_paths += %W(#{config.root}/app/hyperstack/shared)

  # except for the outer hyperstack directory
  delete_first config.autoload_paths, "#{config.root}/app/hyperstack"
end
```
