## Application File Structure

Hyperstack adds the following files and directories to your Rails
application:

```
/app/hyperstack
/app/operations
/app/policies
/config/initializers/hyperstack.rb
/app/javascript/packs/client_and_server.js
/app/javascript/packs/client_only.js
```

In addition there are configuration settings in existing Rails files that are explained in the next section.  Below we cover the purpose of each these files, and their contents.

### The `/app/hyperstack/` Directory

Here lives all your Hyperstack code.  Some of the subdirectories are *isomorphic* meaning the code is shared between the client and the server, other directories are client only.

Within the `hyperstack` directory there will be the following sub-directories:

+ `components` *(client-only)* is where your components live.   
 Following Rails conventions a component with a class of Bar::None::FooManchu should be in a file named `components/bar/none/foo_manchu.rb`

+ `models` *(isomorphic)* is where ActiveRecord models are shared with the client.  More on this below.

+ `operations` *(isomorphic)* is where Hyperstack Operations will live.

+ `shared` *(isomorphic)* is where you can put shared code that are not models or operations.

+ Any other subdirectory (such as `libs` and `client-ops`) will be considered client-only.

### Sharing Models and Operations

Files in the `hyperstack` `/models` and `/operations` directories are loaded on the client and the server.  So when you place a model's class definition in the `hyperstack/models` directory the class is available on the client.  

```Ruby
  Todo.count # will return the same value on the client and the server
```

> See the Policy section below for how access to the actual data is controlled.  Remember a Model *describes* some data, but the actual data is stored in the database, and protected by Policies.

Likewise Operations placed in the `/operations` directory can be run on the client or the server, or in the case of a `ServerOp` the operation can be invoked on the client, but will run on the server.

Hyperstack sets things up so that Rails will first look in the `hyperstack` `/models` and `/operations` directories, and then in the server only `app/models` and `app/operations` directories.   So if you don't want some model shared you can just leave it in the normal `app` directory.

### Splitting Class Definitions

There are cases where you would like split a class definition into its shared and server-only aspects.  For example there may be code in a model that cannot be sensibly run on the client.  Hyperstack augments the Rails dependency lookup mechanism so that when a file is found in a `hyperstack` directory we will *also* load any matching file in the normal `app` directory.

This works because Ruby classes are *open*, so that you can define a class (or module) in multiple places.

### Server Side Operations

Operations are Hyperstack's way of providing *Service Objects*: classes that perform some operation not strictly belonging to a single model, and often involving other services such as remote APIs.  

As such Operations can be useful strictly on the server side, and so can be added to the `app/operations` directory.

Server side operations can also be remotely run from the client.  Such operations are defined as subclasses of `Hyperstack::ServerOp`.  

The right way to define a `ServerOp` is to place its basic definition including its parameter signature in the `hyperstack/operations` directory, and then placing the rest of the operations definition in the `app/operations` directory.

### Policies

Hyperstack uses Policies to define access rights to your models.  Policies are placed in the `app/policies` directory.  For example the policies for the `Todo` model would defined by the `TodoPolicy` class located at `app/policies/todo_policy.rb`  Details on policies can be found [Policy section of this document.](https://docs.hyperstack.org/isomorphic-dsl/hyper-policy).

### Example Directory Structure
```
└── app/
    ├── models/
    │   └── user.rb # private section of User model
    ├── operations/
    │   └── email_the_owner.rb # server code
    ├── hyperstack/
    │   ├── components/
    │   │   ├── app.rb
    │   │   ├── edit_todo.rb
    │   │   ├── footer.rb
    │   │   ├── header.rb
    │   │   ├── show_todo.rb
    │   │   └── todo_index.rb
    │   ├── models/
    │   │   ├── application_record.rb # usually no need to split this
    │   │   ├── todo.rb # note all of Todo definition is public
    │   │   └── user.rb # user has a public and private section
    │   └── operations/
    │       └── email_the_owner.rb # serverop interface only
    └── policies/
        ├── todo_policy.rb
        └── user_policy.rb

```

These directories are where most of your work will be done during Hyperstack development.

> #### What about Controllers and Views?
Hyperstack works alongside Rails controllers and views.  In a clean-sheet Hyperstack app you never need to create a controller or a view.  On the other hand if you have existing code or aspects of your project that you feel would work better using a traditional MVC approach everything will work fine.  You can also merge the two worlds: Hyperstack includes two helpers that allow you to mount components either from a controller or from within a view.

### The Hyperstack Initializer

The Hyperstack configuration can be controlled via the `config/initializers/hyperstack.rb` initializer file.   Using the installer will set up a reasonable set of of options, which you can tweak as needed.

Here is a summary of the various configuration settings:

```ruby
# config/initializers/hyperstack.rb

# server_side_auto_require will patch the ActiveSupport Dependencies module
# so that you can define classes and modules with files in both the
# app/hyperstack/xxx and app/xxx directories.  

require "hyperstack/server_side_auto_require.rb"

# By default the generators will generate new components as subclasses of
# HyperComponent.  You can change this using the component_base_class setting.

Hyperstack.component_base_class = 'HyperComponent' # i.e. 'ApplicationComponent'

# prerendering is default :off, you should wait until your
# application is relatively well debugged before turning on.

Hyperstack.prerendering = :off # or :on

# The transport setting controls how push (websocket) communications are
# implemented.  The default is :none, but will be set to :action_cable if you
# install hyper-model.

# Other possibilities are :action_cable, :pusher (see www.pusher.com)
# or :simple_poller which is sometimes handy during system debug.

Hyperstack.transport = :action_cable # :pusher, :simple_poller or :none

# hotloader settings:
# sets the port hotloader will listen on.  Note this must match the value used
# to start the hotloader typically in the foreman Procfile.
Hyperstack.hotloader_port = 25222
# seconds between pings over the hotloader websocket.  Normally not needed.
Hyperstack.hotloader_ping = nil
# hotloader will automatically reload callbacks when effected classes are
# reloaded.  Not recommended to change this.
Hyperstack.hotloader_ignore_callback_mapping = false

# Transport settings
# seconds before timeout when sending messages between the rails console and  
# the server.
Hyperstack.send_to_server_timeout = 10

# Transport specific options
Hyperstack.opts, {
  # pusher specific options
  app_id: 'your pusher app id',
  key: 'your pusher key',
  secret: 'your pusher secret',
  cluster: 'mt1', # pusher cluster defaults to mt1
  encrypted: true, # encrypt pusher comms, defaults to true
  refresh_channels_every: 2.minutes, # how often to check which channels are alive

  # simple poller specific options
  expire_polled_connection_in: 5.minutes, # when to kill simple poller connections
  seconds_between_poll: 5.seconds, # how fast to poll when using simple poller
  expire_new_connection_in: 10.seconds, # how long to keep initial sessions alive
}

# Namespace used to keep hyperstack communication separate from other websockets
Hyperstack.channel_prefix = 'synchromesh'

# If there a JS console available should websocket comms be logged?
Hyperstack.client_logging = true

# Automatically create a (possibly temporary) websocket connection as each
# browser session starts.  Usually this is needed for further authentication and
# should be left as true
Hyperstack.connect_session =  true

# Where to store the connection tables.  Default is :active_record but you
# can also specify redis.  If specifying redis the redis url defaults to
# redis://127.0.0.1:6379
Hyperstack.connection = [adapter: :active_record] # or
                      # [adapter: :redis, redis_url: 'redis://127.0.0.1:6379]

# The import directive loads optional portions of the various hyperstack gems.
# Here are the common imports typically included:

Hyperstack.import 'hyperstack/hotloader', client_only: true if Rails.env.development?

# and these are typically not imported:

# React source is normally brought in through webpacker
# Hyperstack.import 'react/react-source-browser'

# add this line if you need jQuery AND ARE NOT USING WEBPACK
# Hyperstack.import 'hyperstack/component/jquery', client_only: true

# The following are less common settings which you should never have to change:
Hyperstack.prerendering_files = ['hyperstack-prerender-loader.js']
Hyperstack.public_model_directories = ['app/hyperstack/models']


# change definition of on_error to control how errors such as validation
# exceptions are reported on the server
module Hyperstack
  def self.on_error(operation, err, params, formatted_error_message)
    ::Rails.logger.debug(
      "#{formatted_error_message}\n\n" +
      Pastel.new.red(
        'To further investigate you may want to add a debugging '\
        'breakpoint to the on_error method in config/initializers/hyperstack.rb'
      )
    )
  end
end if Rails.env.development?
```

### Hyperstack Packs

Rails `webpacker` organizes javascript into *packs*.  Hyperstack will look for and load one of two packs depending on if you are prerendering or not.

The default content of these packs are as follows:

```javascript
//app/javascript/packs/client_and_server.js
// these packages will be loaded both during prerendering and on the client
React = require('react');                         // react-js library
createReactClass = require('create-react-class'); // backwards compatibility with ECMA5
History = require('history');                     // react-router history library
ReactRouter = require('react-router');            // react-router js library
ReactRouterDOM = require('react-router-dom');     // react-router DOM interface
ReactRailsUJS = require('react_ujs');             // interface to react-rails
// to add additional NPM packages run `yarn add package-name@version`
// then add the require here.
```

```javascript
//app/javascript/packs/client_only.js
// add any requires for packages that will run client side only
ReactDOM = require('react-dom');               // react-js client side code
jQuery = require('jquery');                    // remove if you don't need jQuery
// to add additional NPM packages call run yarn add package-name@version
// then add the require here.
```
