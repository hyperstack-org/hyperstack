# Installation and Setup (~> 1.0.alpha1.5)

You can install a single `HyperComponent` or the complete 'Stack  in your Rails app using the built in generators and Rake tasks, with as little as two commands.  You can also manually install the pieces following the detailed guide below.

## Pre-Requisites

For any setup you need:

#### - Rails 5.x ([Install Instructions](http://railsinstaller.org/en))
And for a full system that includes Webpack for managing javascript assets you will need:
#### - Yarn ([Install Instructions](https://yarnpkg.com/en/docs/install))
#### - NodeJS: ([Install Instructions](https://nodejs.org))


## Creating a Test Rails App

You can install Hyperstack in existing Rails apps, or you can create a new Rails app using the Rails `new` command.  For example to create a new app called `MyApp` you would run

```
rails new MyApp -T
```

which will create a new directory called `MyApp`.  *Be sure to cd into the new directory when done.*

> The -T option prevents Rails from installing the minitest directories.  Hyperstack uses the alternate rspec test framework for testing.  If you are installing in an existing Rails app and already using mini-test that's okay.

## Adding the Hyperstack gem

Once you have a new (or existing) Rails app, add the rails-hyperstack gem to your Gemfile, and then bundle install.  This can be done in one step by running:

> **Be sure you cd into the new directory if you just created a new Rails app**

```
bundle add 'rails-hyperstack' --version "~> 1.0.alpha1.0"
```

> If you want to use the unreleased edge branch your gem specification will be:
```ruby
gem 'rails-hyperstack',
     git: 'git://github.com/hyperstack-org/hyperstack.git',
     branch: 'edge',
     glob: 'ruby/*/*.gemspec'
```

## Doing a Full Install

After the Hyperstack gem is installed you can do a full install by running:
```
bundle exec rails hyperstack:install
```
This will install the following pieces:
+ A skeleton top level router component named `App` *(only on new apps)*
+ A Rails route that will send all requests to that component *(only on new apps)*
+ The webpacker gem and associated files to integrate Hyperstack with webpack
+ HyperModel to give your client components access to your Rails models
+ The Hotloader which will update the client when you make changes to code

Each of the above pieces can be skipped or installed independently either using
built in installers and generators, or manually as explained in the
following sections.

> The top level component, and route is only installed if a new Rails app is detected.  Otherwise you will have to choose how you want to mount your components, depending on the needs of your application.  See [How to add components](#user-content-adding-a-single-component-to-your-application) and [mount them](#mounting-components) for details.


At this point you're fully installed.

> **Note the first time you run your app it will take 1-2 minutes to compile all the system libraries.**

If you installed into a new rails app you can run

    bundle exec foreman start

to start the server, and **App** will display on the top left hand side of the page.  You will find the `App` component in the `app/hyperstack/components/app.rb` file.  If you edit this file and save it you will see the changes reflected immediately in the browser.

If you installed into an existing Rails app, your app should function exactly as it always has. You can also use `bundle exec foreman start` to start the server and the hotloader. From here, you'll need to start adding components and
and using them from either a view or a controller. See [How to add components](#adding-a-single-component-to-your-application) and [mount them](#mounting-components) for details.

## Summary of Installers and Generators

The following sections details the installers and generators you can use for full control of the installation process.  Details are also given on exactly what each installer and generator does if you want to manually apply the step or modify it to your needs.

```
bundle exec ... # for best results always use bundle exec!
rails hyperstack:install                  # full system install
rails hyperstack:install:webpack          # just add webpack
rails hyperstack:install:skip-webpack     # all but webpack
rails hyperstack:install:hyper-model      # just add hyper-model
rails hyperstack:install:skip-hyper-model # all but hyper-model
rails hyperstack:install:hotloader        # just add the hotloader
rails hyperstack:install:skip-hotloader   # skip the hotloader

rails g hyper:component CompName     # adds a component named CompName
rails g hyper:router CompName        # adds a router component

# Note: rails g ... is short for rails generate

# Both generators can take a list of components.  Component names can be
# any legal Ruby class name.  For example Module1::ComponentA will work.

# The generators will insure the minimum necessary configuration is setup,
# so you can run them immediately after adding the hyperstack gem to try
# out hyperstack.

# optional switches for the generators:
# --add-route="..route specification.."  # adds a rails route to the generated
                                         # component
# --add-route                            # same as --add-route="/(*others)"
# --base-class=ApplicationComponent      # uses ApplicationComponent instead of
                                         # HyperComponent as the base class
# --no-help                              # don't add helper comments

# Note: the --add-route switch will not work if multiple components are generated.

# Note: you can override the component base class for the entire application
# by setting the Hyperstack `component_base_class` config option.  See config options in the
# last section.

# Note: that hyperstack:install is the same as running:

rails g hyper:component App --add-route
rails hyperstack:install:webpack
rails hyperstack:install:hyper-model
rails hyperstack:install:hotloader
```

## The `app/hyperstack` Directory

Hyperstack adds a new directory to your rails app to hold all the Ruby code that will run
on the client.

The following subdirectories are standard:
```
app/
  ...
  hyperstack/
    components/   <- runs on client/prerendering
    models/       <- isomorphic
    operations/   <- isomorphic
    stores/       <- runs on client/prerendering
    shared/       <- isomorphic
    lib/          <- runs on client/prerendering
                  <- others are client/prerendering
```

The `models`, `operations`, and `shared` directories are *isomorphic*. That is the code will
be run on both the Rails server, on the client and during prerendering.  All other directories (regardless of the name)
will only be visible on the client and during prerendering.

These directories will be created as required by the installers and generators, or you can create them yourself as needed.

## Adding a Single Component to Your Application

To add a new component named `Test` (for example) run
```
bundle exec rails generate hyper:component Test
```
This will peform the following tasks:
+ Insure the `//= require hyperstack-loader` directive is in your `app/assets/javascripts/application.js` file.
+ Insure there is a `app/hyperstack/components` directory where all your component classes will be kept.
+ Insure there is a `HyperComponent` base class defined.
+ Add a skeleton component named `Test`

In Rails *by convention* all of your controllers inherit from the `ApplicationController` class,
and all your Models inherit from the `ApplicationRecord` class.  Likewise all your
components will inherit from the `HyperComponent` class.
This allows you to customize the overall behavior of your components by modifying
the `HyperComponent` class.

The default `HyperComponent` class definition added by the generator looks like this:
```ruby
# app/hyperstack/components/hyper_component.rb
class HyperComponent
  # All component classes must include Hyperstack::Component
  include Hyperstack::Component
  # The Observable module adds state handling
  include Hyperstack::State::Observable
  # The following turns on the new style param accessor
  # i.e. param :foo is accessed by the foo method
  param_accessor_style :accessors
end
```
> Note: You can override the base class name using the `--base-class` switch:
> For example if you prefer ApplicationComponent rather than HyperComponent
```bash
bundle exec rails g hyper:component Test --base-class=ApplicationComponent
```
> You can also override the base class for the entire application by setting
> the `component_base_class` config setting.  See [Summary of Hyperstack Configuration Switches](#summary-of-hyperstack-configuration-switches) for details.

## Mounting Components

Components render (or *mount*) other components in a tree-like fashion. You can mount the top level component of  the tree in three different ways:
+ Render it from a controller using the `render_component` method
+ Mount it from within a view using the `mount_component` view helper
+ Route to it from the Rails router

#### Rendering from a Controller Action

For example
```ruby
class SomePage < ApplicationController
  def show
    render_component # will render the Show component
  end
end
```
You may also explicitly pass the component name
```ruby
  render_component 'Dashboard'
```
pass parameters to the component
```ruby
  render_component 'Dashboard', user: @user
```
and override the default layout
```ruby
  render_component 'Dashboard', {user: @user}, layout: :none
```
> Notice how `render_component` works very much like the standard Rails `render` method, except a component is rendered instead of a view.

#### Mounting from Within a View or Layout

For example
```erb
   <%= mount_component 'Dashboard', user: @user %>
```
will display the `Dashboard` component at this position in the
code, very similar to displaying a view or partial.
> Note that you may have several component trees mounted in a single page using the `mount_component` helper.  While this is not typical for a clean sheet Hyperstack design, it is useful when mixing Hyperstack with legacy applications.


#### Directly Routing to a Component

For example
```ruby
Rails.application.routes.draw do
  ...
  get '/dashboard', to: 'hyperstack#dashboard'
  ...
end
```
will mount the `Dashboard` component when the `/dashboard` page loads.

## Adding a Top Level Router Component

For an SPA (Single Page App) you will typically want to route some set of URLs
to a top level component that will then handle what to display as the URL changes.

To do this you would set up the following route in your Rails router:

```ruby
Rails.application.routes.draw do
  ...
  get '/(*others)', to: 'hyperstack#app'
  ...
end
```
This will match any URL and mount the `App` component.  You will then want to
include the `Hyperstack::Router` module in the `App` component which will add
methods to respond to changes in the URL without reloading the page:
```ruby
class App < HyperComponent
  include Hyperstack::Router
  render do
    ...
  end
end
```

You can do all this in one step using the Router generator:
```
rails generate hyper:router App --add-route
```
This will add the route to Rails, and add a component named `App` that
includes the `Hyperstack::Router` module as well helpful comments on the
various routing methods.

> Note that in a large app you may have several single page apps working together,
along with some legacy routes.
In such an application the router structure might look like this:
```ruby
Rails.application.routes.draw do
  ... # legacy routes
  get '/admin/(*others)', to: 'hyperstack#admin'
  get '/cart/(*others)',  to: 'hyperstack#cart'
  get '/(*others)',       to: 'hyperstack#home'
  ...
end
```

The `--add-route` option can also specify the specific Rails route you want added when the component is created:

```
# route only /test to the Test component
bundle exec rails g hyper:router Test --add-route="/test"
# adds `get '/test', to: 'hyperstack#test'` to routes.rb

# route any route beginning with /test/
bundle exec rails g hyper:router Test --add-route="/test/(*others)"
# adds `get '/test/(*others)', to: 'hyperstack#test'` to routes.rb

# note --add-route by itself is the same as
bundle exec rails g hyper:router Test --add-route="/(*others)"
```

> Note that you can use the `add-route` option with the `hyper:component` generator as well.  Both generators
work the same, but just generate different skeleton components.

## Using Webpacker

Using the Rails `webpacker` gem you can easily add other NPM (node package manager) assets to your Hyperstack application.  This allows your Hyperstack components to use any of the thousands of existing React component libraries, as well as packages like jQuery.

> Note that you will need to have yarn and nodejs installed:  
> [Yarn Install Instructions](https://yarnpkg.com/en/docs/install)  
> [Node Install Instructions](https://nodejs.org)

For details on how to import and use NPM packages in your application see [Importing React Components](https://hyperstack.org/edge/docs/dsl-client/components#javascript-components)

To integrate webpacker with an existing Hyperstack application - for example if you just added a couple of components and now
want to try webpacker - use the `hyperstack:install:webpack` task:
```
bundle exec rails hyperstack:install:webpack
```
This will do the following:
+ Insure node and yarn are installed
+ Install the Webpacker gem
+ Add the Hyperstack Webpacker manifests
+ Manage the Hyperstack dependencies with yarn

You can manually perform the above steps following the instructions below.

#### Yarn and Node

Yarn is an NPM package manager.  Its role is similar to bundler in the Ruby world.  Like bundler it uses a `.lock` file to track the current set of dependencies.  Unlike
bundler there is no equivilent of the `Gem` file.  Instead you add packages directly into the yarn data base by running `yarn add` commands.  Yarn also depends on NodeJS so you will need to install that if you have not already.

Yarn can be installed following these instructions: [Install Instructions](https://yarnpkg.com/en/docs/install#mac-stable)  
Node can be installed following these instructions: [Node Install Instructions](https://nodejs.org)

#### The Webpacker Gem

The Webpacker Gem uses a node package called Webpack to manage NPM assets instead of sprockets.  So once you have webpacker installed you will want to bring in any javascript
libraries using Yarn, and let webpacker manage them instead of including them as wrapped Ruby gems or as files in the rails assets directory.

To install webpacker manually add the `webpacker` gem to your gem file and run `bundle install` or simply run
```
bundle add webpacker
```
After adding the gem you will need to run the webpacker setup task:
```
bundle exec rails webpacker:install
```

#### The Hyperstack Webpacker Manifests

Webpacker uses manifests to determine how to package up assets.  Hyperstack depends on two manifests: One that builds assets that are loaded both during prerendering **and** on the client, and a second that is **only** loaded on the client.

> Prerendering builds the initial page view server side, and then delivers it to the client as a normal static HTML page.  Attached to the HTML are flags that React will use to update the page as components are re-rendered after the initial page load.
>
> This means that page load time is comparable to any other Rails view, and that Rails can cache the pages like any other view.
>
> But to make this work packages that rely on the `browser` object cannot be used during prerendering.  Well structured packages that depend on the `browser` object will have a way to run in the prerendering environment.

These two files look like this and are placed in the `app/javascript/packs` directory:
```javascript
//app/javascript/packs/client_and_server.js
// these packages will be loaded both during prerendering and on the client
React = require('react');                      // react-js library
History = require('history');                  // react-router history library
ReactRouter = require('react-router');         // react-router js library
ReactRouterDOM = require('react-router-dom');  // react-router DOM interface
ReactRailsUJS = require('react_ujs');          // interface to react-rails
// to add additional NPM packages call run yarn add package-name@version
// then add the require here.
```
```javascript
//app/javascript/packs/client_only.js
// add any requires for packages that will run client side only
ReactDOM = require('react-dom');               // react-js client side code
// jQuery = require('jquery');                 // uncomment if you want jquery
// to add additional NPM packages call run yarn add package-name@version
// then add the require here.
```

Finally we need to tell Rails where to look to find these manifests:

In `config/initializers/assets.rb` add the following line at the end of the file:

```ruby
  Rails.application.config.assets.paths <<
    Rails.root.join('public', 'packs', 'js').to_s
```

and in `config/environments/test.rb` add the following line before the
final `end` statement:

```ruby
# config/environments/test.rb
Rails.application.configure do
  # other stuff...

  config.assets.paths <<
    Rails.root.join('public', 'packs-test', 'js').to_s
end
```

#### Manage the Hyperstack dependencies with yarn

As you can see above the NPM modules that Hyperstack depends on are part of the webpacker manifests.
But by default Hyperstack will pull copies of these packages into the old-school Rails sprockets asset pipeline.
So if you are using Webpacker you need to add the packages using yarn, and then tell Hyperstack not to
include them in the sprockets asset pipeline.

To add the packages using yarn run these commands:

```bash
yarn add react@16
yarn add react-dom@16
yarn add react-router@^5.0.0
yarn add react-router-dom@^5.0.0
yarn add react_ujs@^2.5.0
yarn add jquery@^3.4.1
```
And then add a `cancel_import` directive to the `hyperstack.rb` initializer in your the Rails `config/initializers` directory:

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  config.cancel_import 'react/react-source-browser'
end
```
> Note: You may have to create the initializer if it is not already there, otherwise
just add the cancel_import directive to the existing initializer.

## Adding Policies and Integrating with ActiveRecord

The `hyper-model` gem (which is included in the `rails-hyperstack` gem) mirrors the portions of your ActiveRecord models that a page
is currently using.  As data changes either on the client or the server both the server and client are kept in sync.
Security is a key concern and is implemented using **Policy** classes.  Before any data is accessible on the client there must be a
policy giving the client permission.

To install `hyper-model` into an existing hyperstack application use the `hyperstack:install:hyper-model` task:
```
bundle exec rails hyperstack:install:hyper-model
```
This will perform the following actions:
+ Create a Development Policy
+ Move `app/models/application_record.rb` to `app/hyperstack/models/`
+ Create a stub `app/models/application_record.rb` file

Once `hyper-model` is installed you can move any models you want to use on the client from the `app/models` directory to `app/hyperstack/models` directory

You can manually perform the above three steps following these instructions:

#### Create a Development Policy

Hyperstack uses Policies to control communication between the client and server.  Policies go in the `app/policies` directory.  The following Policy will give unrestricted access to your models **unless in production:**

```ruby
# app/policies/application_policy.rb

# Policies regulate access to your public models
# The following policy will open up full access (but only in development)
# The policy system is very flexible and powerful.  See the documentation
# for complete details.
class Hyperstack::ApplicationPolicy
  # Allow any session to connect:
  always_allow_connection
  # Send all attributes from all public models
  regulate_all_broadcasts { |policy| policy.send_all }
  # Allow all changes to models
  allow_change(to: :all, on: [:create, :update, :destroy]) { true }
  # allow remote access to all scopes - i.e. you can count or get a list of ids
  # for any scope or relationship
  ApplicationRecord.regulate_scope :all
end unless Rails.env.production?
```

This policy specifies the following:
1. allow any client to connect to the `Hyperstack::Application`
2. the server will broadcast all data changes to the `Hyperstack::Application`
3. the application can create, update and destroy all models
4. the client can filter all models using any scope

**But only if we are not running in production!**

As your application develops you can begin defining more restrictive policies (only allowing Users to see their own data for example)

> Note: The policy mechanism does not depend on [Pundit](https://github.com/varvet/pundit) but is compatible with it.  You can add pundit style
policies for legacy parts of your system.  
>  
> For details on creating policies see the [policy documentation](https://hyperstack.org/edge/docs/dsl-isomorphic/policies).

#### Moving the `application_record.rb` File.

Once you have a basic Policy defined the client can access your Rails models.  For your ActiveRecord model class definitions to be visible on the client you need to move them to the `app/hyperstack/models` directory.  This directory (along with `app/hyperstack/operations` and `app/hyperstack/shared`) are *isomorphic* directories.  The code in these directories will be accessible on both the client and the server.
> Moving the files is necessary both because of the way Rails is structured, but its also very useful when evolving legacy systems to Hyperstack.  Until a class
definition is moved to the `hyperstack/models` directory it will be ignored by Hyperstack.

In a typical Rails application all model classes are subclasses of `ApplicationRecord`. So as a first step you need to move `application_record.rb` from the
`app/models/application_record.rb` to `app/hyperstack/models/application_record.rb`

#### Create a stub `app/models/application_record.rb` file

At this point everything will work, and if you move a model's class definition from `app/models/` to `app/hyperstack/models` that class can now be used on the
client **subject to any restrictions in your policies.**.

However when you next run a Rails migration, Rails will discover that there is no `app/models/application_record.rb` file (because you moved it) and will generate a new one for you!

So to prevent that you need to add this file to `app/models`
```ruby
# app/models/application_record.rb
# the presence of this file prevents rails migrations from recreating application_record.rb
# see https://github.com/rails/rails/issues/29407

# this will grab the real file from the hyperstack directory
require 'models/application_record.rb'
```
> Note that the last line is *not* a typo.  Rails paths begin with
a *subdirectory* name.  So `'models/application_record.rb'` means to search all app directories for a file name `application_record.rb` in a `models` *subdirectory*

Thus Rails will find `app/models/application_record.rb` where it expects it, but that file simply requires the real `application_record.rb` file from the `app/hyperstack/models` directory so everybody is happy.

## Installing the Hotloader

The Hotloader watches your directories, and when client side files change, it will compile those files, and surgically update the client environment to contain the new code.  The update process is near instantaneous, so it makes developing and debugging components easy.

You can add the Hotloader by running:
```
bundle exec rails hyperstack:install:hotloader
```
This will perform the following actions:
+ Import the Hotloader into your `hyperstack-loader` manifest;
+ Add the `foreman` gem to your `Gemfile` and
+ Add a `Procfile` used by foreman to the root of our application directory.

You can manually perform these steps following these instructions.

#### Importing the Hotloader

By default the Hotloader is **not** included in the hyperstack manifest so the first step is to import it using `config/initializers/hyperstack.rb` initializer file:

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  # we don't need or want the Hotloader running in test
  # or production so we put the import on a switch, so
  # the import only occurs in development.
  config.import 'hyperstack/hotloader',
                client_only: true if Rails.env.development?
end
```
> Note: You may have to create the initializer if it is not already there, otherwise
just add the import directive to the existing initializer.

Because you have changed the system manifest its best to clear the Rails cache to insure the new configuration is rebuilt, and not loaded from cache.  In the shell run
```
rm -rf tmp/cache # clear the cache
```

The Hotloader needs to run in a separate process, so bring up a separate terminal window and run
```bash
bundle exec hyperstack-hotloader -p 25222 -d app/hyperstack
```
This will tell the Hotloader to use port 25222, and to scan the
`app/hyperstack` directory.

> If for some reason you cannot use port 25222 you can change it, but you need to also configure this in the Hyperstack initializer file:
```ruby
  ...
  config.hotloader_port = 12345 # override default of 25222
  ...
```

Now that the Hotloader is running, you can start your Rails server the normal way, and refresh your browser page.
You should now see `require 'hyperstack/hotloader' # CLIENT ONLY` added to the manifest,
and you will also see a message indicating that your browser has connected to the Hotloader.

Now go into your editor and make a change to a component.  You should see the browser window updating as soon as you save the file.

#### Adding the Foreman Gem and Procfile

Having to start (and stop) two separate shells is painful so you can add the `foreman` gem which will manage all that for you.  Add
the `foreman` gem to the development section of your Gemfile and bundle install.  You can do this in one step by running:
```ruby
  bundle add foreman --group development
```

Now add the following `Procfile` to the root of your applications directory:
```text
web:        bundle exec rails s -b 0.0.0.0
hot-loader: bundle exec hyperstack-hotloader -p 25222 -d app/hyperstack
```

Now stop both our server and hotloader processes if they are still running, and then run
```
bundle exec foreman start
```
Which will have foreman start both the processes, and will also allow a single CTRL-C to cancel both processes.

By convention when using foreman we load the server over port 5000, so you will visit `localhost:5000` instead of `locahost:3000`.

## Summary of Hyperstack Configuration Switches

Various default behaviors of the Hyperstack system can be overridden in the hyperstack initializer file.

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  # set the component base class
  config.component_base_class = 'HyperComponent' # i.e. 'ApplicationComponent'

  # prerendering is by default :off. You should wait until your
  # application is relatively well debugged before turning on.
  config.prerendering = :off # or :on

  # transport controls how push (websocket) communications are
  # implemented.  The default is :action_cable.
  # Other possibilities are :pusher (see www.pusher.com) or
  # :simple_poller which is sometimes handy during system debug.
  config.transport = :action_cable # or :none, :pusher,  :simple_poller

  # when you make DB changes via a Rails console, rake task, or other
  # non-server process, Hyperstack needs to forward the change notification
  # to the server for push broadcasting.  This value controls how long
  # Hyperstack will wait to hear back from the server.
  config.send_to_server_timeout = 10 # seconds or nil for no timeout

  # pusher specific setting.  If you are already using pusher you
  # may want to change this
  config.channel_prefix = 'synchromesh'

  # if the transport provides client logging capability then turn it on
  # you may want to switch this like this:  = Rails.env.debug?
  config.client_logging = true

  # Setup a session channel.  Turning this off is mainly useful in test specs
  config.connect_session = true

  # if you need to change the hotloader port
  config.hotloader_port = 25222 # note also update your proc file as well

  # turn pinging on if your hotloader connection keeps dropping
  config.hotloader_ping = nil # 10 seconds for example

  # callback mapping allows the hotloader to reprogram callbacks
  # however it adds additional overhead on first load.  On large systems
  # you may want to turn this off, and then do a full reload if you change
  # any component callbacks.
  config.hotloader_ignore_callback_mapping = false

  # Hyperstack provides an import directive to pull in ruby code from existing
  # Opal gems (including hyperstack internal gems)

  config.import 'path/to/file'  # add the file to the ruby manifest
  config.import 'path/to/file', client_only: true # but only in the client manifest
  config.import 'path/to/file', server_only: true # but only on the server_only manifest

  # The cancel_import directive removes an import.  This is used when we replace
  # assets from the rails side with those loaded by webpacker
  config.cancel_import 'path/to/file'
end

# Hyperstack provides a hook to aid in debugging communication problems.  The following
# code block adds a useful server side log message.  You may want to change this to
# a specific logging location, or on occasion add a debug break point instead of logging

module Hyperstack
  def self.on_error(operation, err, params, formatted_error_message)
    ::Rails.logger.debug(
      "\#{formatted_error_message}\\n\\n" +
      Pastel.new.red(
        'To further investigate you may want to add a debugging '\\
        'breakpoint to the on_error method in config/initializers/hyperstack.rb'
      )
    )
  end
end if Rails.env.development?

```
