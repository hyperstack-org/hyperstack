# Installation

You can install hyperstack either
+ using a template - best for new applications;
+ using a Rails generator - best for existing Rails apps;
+ or manually walking through the detailed installation instructions.

## Pre-Requisites

+ Rails 5.x
+ Yarn must be installed (https://yarnpkg.com/en/docs/install#mac-stable)

## Installing using the template

This template will create a new Rails app with Webpacker from Hyperstack edge branch

### Usage

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
+ Add the `policy` directory and a base `application_policy.rb` file
+ Add the `hyperstack.rb` initializer file
+ Integrate with webpacker
+ Add the Hyperstack engine to the routes file
+ Add/Update the Procfile

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
