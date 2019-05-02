# Installation

You can install hyperstack either
+ using a template - best for new applications;
+ using a Rails generator - best for existing Rails apps;
+ or manually walking through the detailed installation instructions.

Even if you use the template or generator, later reading through the 
detailed installation instructions can be helpful to understand how the
system fits together.

## Pre-Requisites

+ Rails 5.x
+ Yarn must be installed (https://yarnpkg.com/en/docs/install#mac-stable)

## Installing using the template

This template will create a new Rails app with Webpacker from Hyperstack edge branch

### Run the template

Simply run the command below to create a new Rails app with Hyperstack all configured:

```
rails new MyApp -m https://rawgit.com/hyperstack-org/hyperstack/edge/install/rails-webpacker.rb
...or
rails new MyApp -m rails-webpacker.rb
```

### Start the Rails app

+ `foreman start` to start Rails and OpalHotReloader
+ Navigate to `http://localhost:5000/`

## Installing in an Existing Rails App

+ add `gem 'rails-hyperstack', "~> 1.0.alpha1"` to your gem file
+ run `bundle install`
+ run `rails g hyperstack:install`

### Start the Rails app

+ `foreman start` to start Rails and OpalHotReloader
+ Navigate to `http://localhost:5000/`

## Manual Installation

These are the various parts of the system that must be updated for Hyperstack:

+ Insure yarn is loaded
+ Add the gems
+ Update the `application.js` file
+ Add the `hyperstack` directories
+ Add the `HyperComponent` base class
+ Replicate the `application_record.rb` file
+ Add a basic `application_policy.rb` file
+ Add the `hyperstack.rb` initializer file
+ Integrate with webpacker
+ Add the Hyperstack engine to the routes file
+ Add/Update the Procfile

There are quite a few steps, but each has a specific, and understandable purpose.

### Insure `yarn` is loaded

Yarn is used to load and manage NPM assets.  

See https://yarnpkg.com/en/docs/install for details

### Add the gems

Add
```ruby
  gem 'rails-hyperstack', '~> 1.0.alpha1.0'
  gem 'webpacker' # if not already present
  # foreman manages multiple processes, its needed with hotloader only
  gem 'foreman', group: :development
```

Then `bundle install`.

And if you just added webpacker make sure to run `bundle exec rails webpacker:install`

### Update the `application.js` file

The `hyperstack-loader` is a dynamically generated asset that will load all your client side Ruby code. Make it is the last require in `app/assets/javascripts/application.js` file.

`jQuery` is very nicely integrated with Hyperstack, and provides a well
documented uniform interface to the DOM.  To use it require it and its Rails
counter part in `application.js` before the `hyperstack-loader`

```javascript
//= require jquery
//= require jquery_ujs
//= require hyperstack-loader
```

### Add the `hyperstack` directories

Hyperstack will load code out of the `app/hyperstack` directory.  Within this directory there are typically the following subdirectories:

+ `app/hyperstack/components` - Component classes (client only)
+ `app/hyperstack/models` - Shared active record model classes
+ `app/hyperstack/operations` - Shared operation classes
+ `app/hyperstack/stores` - Other data stores (client only)
+ `app/hyperstack/shared` - Misc shared modules and classes
+ `app/hyperstack/lib` - Client only libraries

These directories are all optional.  The `models`, `operations`, and `shared` subdirectories are both used on the client, and will be also included as part of the Rails constant lookup search path.

Any other subdirectories will be treated as client only.  The names listed above such as `components`, `stores` and `lib` are just conventions.  For example you may prefer `client_lib`.

> Note that you will still have a `app/models` directory, which can be used to keep server-only models.  This is useful for models that will never be accessed from the client to reduce payload size.  You can also add an `app/operations` directory if you wish to have Operations that only run on the server.

### Add the HyperComponent base class

The Hyperstack convention is for each application to define a `HyperComponent` base class, from which all of your other components will inherit from.  This follows the modern Rails convention used with Models and Controllers.

The typical `HyperComponent` class definition looks like this:

```ruby
# app/hyperstack/hyper_component.rb
class HyperComponent
  # All component classes must include Hyperstack::Component
  include Hyperstack::Component
  # The Observer module adds state handling
  include Hyperstack::State::Observer
  # The following turns on the new style param accessor
  # i.e. param :foo is accessed by the foo method
  param_accessor_style :accessors
end
```

> Note that this is only convention.  The Hyperstack system assumes nothing about HyperComponent or how you define components.  Any class that includes the `Hyperstack::Component` module will be a component.

### Replicate the `application_record.rb` file

Model files typically inherit from the `ApplicationModel` class, so you must move the
`app/models/application_record.rb` to `app/hyperstack/models/application_record.rb` so
that it is accessible both on the client and server.

However Rails will automatically generate a new `application_record.rb` file if it does
not find one in the `app/models` directory.  To prevent create a new `app/models/application_record.rb` that looks like this:

```ruby
# app/models/application_record.rb
# the presence of this file prevents rails migrations from recreating application_record.rb see https://github.com/rails/rails/issues/29407

# this will grab the real file from the hyperstack directory
require 'models/application_record.rb'
```

### Add a basic `application_policy.rb` file

Your server side model data is protected by *Policies* defined in Policy classes stored in the `app/policy` directory.  The following file creates basic a *"wide open"* set of
policies, for development mode.  You will then need to add specific Policies to protect
your data in production model.

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

### Add the `hyperstack.rb` initializer file

Add the following file to the `config/initializers/` directory:

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  # If you are not using ActionCable,
  # see http://hyperstack.orgs/docs/models/configuring-transport/
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

The on_error method defines what you want to do when errors occur.  In production
you will may want to direct the output to a dedicated log file for example.

### Integrate with webpacker

@barriehadfield - HELP!

### Add the Hyperstack engine to the routes file

At the beginning of `config/routes.rb` file mount the Hyperstack engine:

```ruby
```
