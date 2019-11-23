# Installation

You can install Hyperstack either
+ using a template - best for new applications (not working for Rails 6) yet;
+ using a Rails generator - best for existing Rails apps;
+ or manually walking through the detailed installation instructions below.

Even if you use the template or generator, later reading through the
detailed installation instructions can be helpful to understand how the
system fits together and the generators work.

## Pre-Requisites

#### - Rails 5.x [Install Instructions](http://railsinstaller.org/en)

And for a full system as setup by the template or install generator you will need

#### - Yarn [Install Instructions](https://yarnpkg.com/en/docs/install#mac-stable)

## Installing using the template

This template will create a **new** Rails app with Webpacker from Hyperstack edge branch.  This is the easiest way to get started.

### Run the template

Simply run the command below to create a new Rails app with Hyperstack all configured:

```
rails new MyApp -T -m https://rawgit.com/hyperstack-org/hyperstack/edge/install/rails-webpacker.rb
```
> Note: The -T flag will not install minitest directories, leaving room for Rspec and Hyperspec.  See the HyperSpec readme under "Tools" for more info.

### Start the Rails app

+ `foreman start` to start Rails and the Hotloader
+ Navigate to `http://localhost:5000/`

## Installing in an Existing Rails App

If you have an existing Rails app, you can use the built in generator to install Hyperstack.  Best to create a new branch of course before trying this out.  

+ add `gem 'rails-hyperstack', "~> 1.0.alpha1.0"` to your gem file
+ run `bundle install`
+ run `bundle exec rails g hyperstack:install`

> Note: if you want to use the unreleased edge branch your gem specification will be:  
```ruby
gem 'rails-hyperstack',
     git: 'git://github.com/hyperstack-org/hyperstack.git',
     branch: 'edge',
     glob: 'ruby/*/*.gemspec'
```
### Start the Rails app

+ `bundle exec foreman start` to start Rails and the Hotloader
+ Navigate to `http://localhost:5000/`

> Note that the generator will add a wild card route to the beginning of your routes file.  This will let you immediately test Hyperstack, but will also mean that all of your existing routes are now unreachable.  So after getting Hyperstack up, you will want to adjust things to your needs.  See the first in the **Manual Installation** section for more info.

## Manual Installation

To manually install a complete Hyperstack system there are quite a few steps.  However these can be broken down into six separate activities each of which will leave your system in a working and testable state:

1. Adding the `rails-hyperstack` gem
2. Adding and Mounting Hyperstack Components
3. Installing the Hotloader
4. Integrating with Webpacker
5. Adding Policies and Integrating with ActiveRecord

Steps 3, 4 and 5 can be done in any order, and can be skipped as needed.  The following sections review each of the steps.

## Adding the `rails-hyperstack` gem

Add  
```ruby
  gem 'rails-hyperstack', '~> 1.0.alpha1.0'
```
to your gem file.

Then `bundle install`.  Your Rails app will continue to work as before.

>Note: if you want to use the unreleased edge branch your rails-hyperstack gem specification will be:  
```ruby
gem 'rails-hyperstack',
     git: 'git://github.com/hyperstack-org/hyperstack.git',
     branch: 'edge',
     glob: 'ruby/*/*.gemspec'
```  

## Adding and Mounting Hyperstack Components

Once you have added the `rails-hyperstack` gem to your system you can easily add a new component to your system by running the following command:

`bundle exec rails g hyper:component TestApp --add-route="/test/(*others)"`

After running this command you should be able to start your server

`bundle exec rails s`

and visit `localhost:3000/test` and you will see **TestApp** displayed.

This command accomplishes four tasks which you can also manually perform if you prefer:

1. Insure that the `hyperstack-loader` is required in your `application.js` file;
2. Insure that you have a `HyperComponent` base class defined;
3. Add a skeleton `TestApp` component and
4. Add a route to the `TestApp` component in your rails routes file.

#### Requiring `hyperstack-loader`

**Each time the `hyper:install`, `hyper:component` and `hyper:router` generators run they insure that the `hyperstack-loader` require is present, and will print a warning if it cannot successfully add it to the `application.js` file.**

The `hyperstack-loader` is a dynamically generated asset manifest that will load all your client side Ruby code. It needs to be the last require in `app/assets/javascripts/application.js` file.  That is it should be just *before* the final `require_tree` directive

```javascript
// assets/javascripts/application.js
...
//= require hyperstack-loader
//= require_tree .
```

Once this is added to your `application.js` file you will see the hyperstack asset manifest on the Rails console and the browser's debug console which looks like this:

```text
require 'opal'
require 'browser' # CLIENT ONLY
require 'hyperstack-config'
require 'hyperstack/autoloader'
require 'hyperstack/autoloader_starter'
require 'hyper-state'
require 'react/react-source-browser' # CLIENT ONLY
require 'react_ujs'
require 'hyper-router'
require 'hyper-model'
require 'browser/delay' # CLIENT ONLY
require 'hyper-component'
require 'hyperstack/component/auto-import'
require 'hyper-operation'
require 'hyperstack/router/react-router-source'
require 'config/initializers/inflections.rb'
```
> Note: By default you will get the entire Hyper Stack, but you can selectively remove parts you do not need in the hyperstack initializer file, which will be discussed later.

#### The HyperComponent base class

**Each time the `hyper:install`, `hyper:component` and `hyper:router` generators run they insure that there is an application defined HyperComponent base class defined in the
`app/hyperstack/components/` directory.  If not present one will be added.**

All your Hyperstack code goes into the `app/hyperstack` directory, which is at the same level as `app/models`, `app/views`, `app/controllers`, etc.

Inside this directory are subdirectories for each of the different parts of you hyperstack application code.  Components go in the `app/hyperstack/components` directory.

Like Rails models, and Rails controllers, Hyperstack components by convention inherit from an application defined base class.  So while a typical Rails model inherits from the `ApplicationRecord` class, your Hyperstack components will inherit from the `HyperComponent` class.

The typical `HyperComponent` class definition looks like this:

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

When the generators run they check for this file, and if not present will add it.

> Note having a HyperComponent base class is only convention.  The Hyperstack system (except for the generators) assumes nothing about HyperComponent or how you define components.  Any class that includes the `Hyperstack::Component` module will be a component.  For example you may want to name your
base class `ApplicationComponent` to more closely following the
rails convention.  
>
> In this case you would have an `app/hyperstack/component/application_component.rb` file that defines your `ApplicationComponent` class.  Then your components would be subclasses of `ApplicationComponent`.
>
> You can even define several base classes.  For example you might define a `StaticComponent` class which does *not* include the `Hyperstack::State:Observable`, and thus create a static (functional) component class.
>
> To tell the generators to use a different base class name use the `--base-class` switch.  For example `--base-class=ApplicationComponent`

#### Add Components

All your components by convention are kept in the `app/hyperstack/components` directory. A simple component would look like this:

```ruby
# app/hyperstack/components/test_app.rb
class TestApp < HyperComponent
  render(DIV)
    "TestApp" # render the string TestApp in a DIV
  end
end
```

Once you add any `.rb` file to any *subdirectory* of `app/hyperstack` it will be added to the `hyperstack-loader` manifest for you.

The `hyper:component` and `hyper:router` generators add a skeleton component file like the one above, after insuring that the `hyperstack-loader` require and the `HyperComponent` base class are present in the correct places.

#### Mount components using the routes file

Now that you have a have a component it needs to be *mounted* for it to be *rendered*.  You have three options for doing this depending on your needs.

The easiest way is to route to your top level component in your Rails `routes` file.  For example if you have a component named `TestApp` you can route to it and mount it by adding the following line near the beginning of the `config/routes.rb` file:

```ruby
get '/test/(*others)', to: 'hyperstack#test_app'
```

Now all URLs beginning with `test/` will bring up a page with `TestApp` mounted in it.

> The first parameter to the `get` route method describes the path that will be matched.  In this case `/test/` followed by any other sub path will match.  When matched the built in `hyperstack` controller will accept the request, and will build a page with the `TestApp` component mounted in it.  Notice the translation of `test_app` to `TestApp`.  

The `hyper:component` and `hyper:router` generators accept an *optional* `add-route` parameter which indicates that you want a route added. The default value for this parameter is the path `/(*others)`:

```text
... --add-route         # adds path '/(*others)'
... --add-route='/fred' # adds path '/fred'
```
#### Mount components using the `render_component` view helper

If you are adding Hyperstack to an existing application you may want to simply mount components somewhere in an existing view.  To do this use the `render_component` view
helper:

```ERB
...
  <% render_component 'TestApp' %>
...
```
will render the component named `TestApp` at that position in your view.  

> The `render_component` helper can also pass parameters to the component so for example if you had a component `DisplayFormattedName`, and your controller had set `@name` you might have this in your ERB file:
```ERB
... <% render_component 'DisplayFormattedName', name: @name %>
```

#### Mount components from a controller

You can also use `render_component` in a controller in place of the standard Rails render method. Like the `render_component` view helper you can pass the component parameters in from the controller.

There are quite a few steps, but each has a specific, and understandable purpose.

## Installing the Hotloader

The Hotloader watches your directories, and when client side files change, it will compile those files, and surgically update the client environment to contain the new code.  The update process is near instantaneous, so it makes developing and debugging components easy.

There are three steps to installing the Hotloader:

1. Importing Hotloader into your `hyperstack-loader` manifest;
2. Adding the `foreman` gem to your `Gemfile` and
3. Adding a `Procfile` to the root of our application directory.

By default the Hotloader is **not** included in the hyperstack manifest so the first step is to add the `config/initializers/hyperstack.rb` initializer file, and *import* the Hotloader:

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  config.import 'hyperstack/hotloader',
                client_only: true if Rails.env.development?
end
```
Note that we don't need or want the Hotloader running in test or production so we put the import on a switch, so the import only occurs in development.

Because you have changed the system manifest its best to clear the Rails cache to insure the new configuration is rebuilt, and not loaded from cache.  In the shell run
```bash
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

Now that the Hotloader is running, you can start your Rails server the normal way, and refresh your browser page.  You should now see `require 'hyperstack/hotloader' # CLIENT ONLY` added to the manifest, and you will also see a message indicating that your browser has connected to the Hotloader.

Now go into your editor and make a change to the component.  You should see the browser window updating as soon as you save the file.

#### Hire a Foreman
Having to start (and stop) two separate shells is painful so you can add the `foreman` gem which will manage all that for you.  Add
```ruby
  gem `foreman` group: :development
```
To your gemfile and do a bundle install.

Now add the following `Procfile` to the root of your applications directory:
```text
web:        bundle exec rails s -b 0.0.0.0
hot-loader: bundle exec hyperstack-hotloader -p 25222 -d app/hyperstack
```

Now stop both our server and hotloader processes if they are still running, and then run
```bash
bundle exec foreman start
```
Which will have foreman start both the processes, and will also allow a single CTRL-C to cancel both processes.

By convention when using foreman we load the server over port 5000, so you will visit `localhost:5000` instead of `locahost:3000`.

### Integrating with Webpacker

Using the Rails `webpacker` gem you can easily add other NPM (node package manager) assets to your Hyperstack application.  This allows you Hyperstack components use any of the thousands of existing React component libraries, as well as packages like jQuery.

There is a bit of configuration needed to add `webpacker` to your application which can be done by running

```bash
bundle exec rails g hyperstack:webpack
```
> Note that you also need to have yarn installed [Install Instructions](https://yarnpkg.com/en/docs/install#mac-stable)

For details on how to import and use NPM packages in your application see [Importing React Components](https://hyperstack.org/edge/docs/dsl-client/components#javascript-components)

To manually install webpacker follow these steps:

#### Insure yarn is installed

[Install Instructions](https://yarnpkg.com/en/docs/install#mac-stable)

#### Add the Hyperstack dependencies

Then run these commands to install Hyperstack's NPM dependencies using yarn:

```bash
yarn 'react', '16'
yarn 'react-dom', '16'
yarn 'react-router', '^5.0.0'
yarn 'react-router-dom', '^5.0.0'
yarn 'react_ujs', '^2.5.0'
```

#### Stop Hyperstack from importing the above dependencies

Because we are now managing these components via yarn, we don't want the Hyperstack loader to include them.  So we use the Hyperstack `cancel_import` config directive in the `config/initializers/hyperstack.rb` file:

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  config.cancel_import 'react/react-source-browser'
end
```

Of course if you already have a `hyperstack.rb` config file, you will be just adding the one `cancel_import` line.

#### Add the Webpacker manifests

Create a new `app/javascript/packs` directory and add these two files:

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
// jQuery = require('jquery');
// to add additional NPM packages call run yarn add package-name@version
// then add the require here.
```

If configured Hyperstack will *prerender* pages serverside, so that the initial download to the client has your component tree already rendered into HTML.  

Because prerendering runs on the server it does not have access to things like the current time, or the window object.  NPM packages that can only sensibly be run on the client are included in the `client_only.js` pack file, while packages designed to be run in the server environment as well go into `client_and_server.js`

#### Add the packs directory to the Rails asset search path

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

#### Add the webpacker gem

Add

```ruby
  gem 'webpacker'
```

to your Gemfile then

```bash
bundle install
```

#### Run the rails webpacker installer

```bash
bundle exec rails webpacker:install
```

This installs all the base webpacker stuff that Rails needs.

## Adding Policies and Integrating with ActiveRecord

Hyperstack uses Policies to control client access to your Models and Operations (Hyperstacks implementation of ServiceObjects.)

Hyperstack shares the contents of the `models`, `operations` and `shared` directories with both the server and the client, so both server and client can access code in those directories.

Together these two mechanisms give you secure access to your models, operations, and other shared code on both the client and server.

#### Steps to Access Models on the Client

1. Create a Development Policy
2. Move `app/models/application_record.rb` to `app/hyperstack/models/`
3. Create a stub `app/models/application_record.rb` file
4. Move any models you want to use on the client from the `app/models` directory to `app/hyperstack/models` directory

Hyperstack uses Policies to control communication between the client and server.  Policies go in the `app/policies` directory.  The following Policy will give unrestricted access to your models unless in production:

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

> Note: The policy mechanism does not depend on [Pundit](https://github.com/varvet/pundit) but is compatible with it.  

Once you have a basic Policy defined the client can access your Rails models.  For your ActiveRecord model class definitions to be visible on the client you need to move them to the `app/hyperstack/models` directory.  This directory (along with `app/hyperstack/operations` and `app/hyperstack/shared`) are *isomorphic* directories.  The code in these directories will be accessible on both the client and the server.  

For example if you have the following class definition
```ruby
class Todo < ApplicationRecord
  scope :active, -> () { where(completed: false) }
  scope :completed -> () { where(completed: true) }
end
```
You could then on the server execute `Todo.active` and get all the todos in the `active` scope.  But as long as this class stays in the `app/models` directory it will not exist on the client.

Once you move the `Todo` class definition to `app/hyperstack/models` it will *also* be visible on the client, and `Todo.active` will now return a list of all active todos on the server and the client.

Because all your ActiveRecord models are (typically) defined as subclasses of `ApplicationRecord`, you need to also move the `app/models/application_record.rb` file to the `app/hyperstack/models/` directory.

At this point everything will work, until you run a Rails migration.  Then Rails will discover that there is no `app/models/application_record.rb` file (because you moved it) and will generate a new one for you!

So to prevent that you need to add this file to `app/models/application_record.rb`
```ruby
# app/models/application_record.rb
# the presence of this file prevents rails migrations from recreating application_record.rb
# see https://github.com/rails/rails/issues/29407

# this will grab the real file from the hyperstack directory
require 'models/application_record.rb'
```
> Note that the last line is *not* a typo.  Rails paths begin with
the *subdirectory* name.  So `'models/application_record.rb'` means to search all directories for a file name `application_record.rb` in the `models` *subdirectory*

### 4. Add the `hyperstack` directories

Hyperstack will load code out of the `app/hyperstack` directory.  Within this directory there are typically the following subdirectories:

+ `app/hyperstack/components` - Component classes (client only)
+ `app/hyperstack/models` - Shared active record model classes
+ `app/hyperstack/operations` - Shared operation classes
+ `app/hyperstack/stores` - Other data stores (client only)
+ `app/hyperstack/shared` - Misc shared modules and classes
+ `app/hyperstack/lib` - Client only libraries

These directories are all optional.  The `models`, `operations`, and `shared` subdirectories are both loaded on the client, and will be also included as part of the Rails constant lookup search path.

Any other subdirectories will be treated as client only.  The names listed above such as `components`, `stores` and `lib` are just conventions.  For example you may prefer `client_lib`.

> Note that you will still have the standard Rails `app/models` directory, which can be used to keep server-only models.  This is useful for models that will never be accessed from the client to reduce payload size.  You can also add an `app/operations` directory if you wish to have Operations that only run on the server.
>
> This does **not** effect security. See the section 7 for how Policies are setup.


### 6. Replicate the `application_record.rb` file

Rails models files normally inherit from the `ApplicationModel` class, so you must move the
`app/models/application_record.rb` to `app/hyperstack/models/application_record.rb` so
that it is accessible both on the client and server.

However Rails will automatically generate a new `application_record.rb` file if it does
not find one in the `app/models` directory.  To prevent this create a new `app/models/application_record.rb` that looks like this:

```ruby
# app/models/application_record.rb
# the presence of this file prevents rails migrations from recreating application_record.rb
# see https://github.com/rails/rails/issues/29407

# this will grab the real file from the hyperstack directory
require 'models/application_record.rb'
```
> Note that the above is *not* a typo.  Rails paths begin with
the *subdirectory* name.  So `'models/application_record.rb'` means to search all directories for a file name `application_record.rb` in the `models` *subdirectory*

### 7. Add a basic `application_policy.rb` file

Your server side model data is protected by *Policies* defined in Policy classes stored in the `app/policy` directory.  The following file creates a basic *"wide open"* set of
policies for development mode.  You will then need to add specific Policies to protect
your data in production mode.

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

  # Allow remote access to all scopes - i.e. you can count or get a list of ids
  # for any scope or relationship
  # You can also add the line `regulate_scope :all` directly to your
  # ApplicationRecord class.
  ApplicationRecord.regulate_scope :all
end unless Rails.env.production?
```

> Note that regardless of whether models are public (i.e stored in the hyperstack/models
directory) or private, they are ultimately protected by the Policy system.  

### 8. Add the `hyperstack.rb` initializer file

Add the following file to the `config/initializers/` directory:

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  # If you do not want to use ActionCable,
  # see http://hyperstack.orgs/docs/models/configuring-transport/
  # for setting up other options.
  config.transport = :action_cable # or :pusher or :simple_poller

  # typically you will want to develop with prerendering off, and
  # once the system is working, turn it on for final debug and test.
  config.prerendering = :off # or :on

  # We bring in React and ReactRouter via Yarn/Webpacker
  config.cancel_import 'react/react-source-browser'

  # remove the following line if you don't need jquery (see notes in application.js)
  config.import 'hyperstack/component/jquery', client_only: true

  # remove this line if you don't want to use the hotloader
  config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
end

# useful for debugging
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

The first section configures Hyperstack and the assets that will be included (or not
included) in the asset manifest.

The `on_error` method defines what you want to do when errors occur.  In production
you will may want to direct the output to a dedicated log file for example.


### 10. Add the Hyperstack engine to the routes file

At the beginning of the `config/routes.rb` file mount the Hyperstack engine:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # this route should be first in the routes file so it always matches
  mount Hyperstack::Engine => '/hyperstack'

   # the rest of your routes here  
end
```

You can mount the engine under any name you please.  All of internal Hyperstack requests will be prefixed with whatever name you use.

>Note: You can also directly ask Hyperstack to mount your top level components
via the routes file.  For example  
```ruby
Rails.application.routes.draw do
  mount Hyperstack::Engine => '/hyperstack' # this must be the first route
  get '/(*other)', to: 'hyperstack#app'
```
> will pass all requests (i.e. `/(*other)`) to the hyperstack engine, and find
and mount a component named `App`.  Whatever you name the engine
mount point (i.e. `hyperstack` in this case) is what you direct the requests to.
>
> Likewise `get /price-quote/(*other), to: hyperstack#price_quote` would mount
a component named `PriceQuote` when the url begins with `price-quote`.
>
> Remember though that the first route that matches will be used, so if you had both examples in your routes, the price-quote route would be before the wildcard route.
>
> This the way you have have 2 or more single page apps served by the same Rails backend.

### 11. Add/Update the Procfile

If you are using the Hotloader, then you will also want to use the `foreman` gem.
The Hotloader runs in its own application process, and foreman will start and stop both Rails and the Hotloader together.

The `foreman` gem is configured by a *Procfile* at the root of your application:

```text
web:        bundle exec rails s -b 0.0.0.0
hot-loader: bundle exec hyperstack-hotloader -p 25222 -d app/hyperstack
```

This instructs foreman to start rails in one process, and
the Hotloader in a second process.  `-p 25222` is the port Hotloader will use
and `-d app/hyperstack` is the directory that will be watched for changes.

To run foreman simply execute `bundle exec foreman start`, and CTRL-C to quit.

> Note when running foreman with the above Procfile your port will be 5000 instead of the usual 3000.

### 12. Using generators

No matter which way you installed Hyperstack you can use the included generators to add new components.

`bundle exec rails g hyper:router App` will create a
skeleton top level (router) component named App.  

`bundle exec rails g hyper:component Index` will create a skeleton component named Index.

### 13. Adding a test component

Once you have installed Hyperstack you have a couple of options to see how things work.  

##### Adding a top level router

The easiest way to make sure everything is installed okay is to use the generator to add an App router

`bundle exec rails g hyper:router App`

and then route everything to this component from your routes file:

`get '/(*other)', to: 'hyperstack#app'`.

##### Mounting a component from an existing page

Another approach is to add a simple component using the component generator:

`bundle exec rails g hyper:component HyperTest`

and then mount this component using ERB from within an existing view:

`<% render_component 'HyperTest' %>`
