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
+ Update the `application.js` files
+ Add the `hyperstack` directories and files
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
  gem 'webpacker'
  # foreman manages multiple processes, its needed with hotloader only
  gem 'foreman', group: :development
```

Then `bundle install`.

And if you just added webpacker make sure to run `bundle exec rails webpacker:install`
