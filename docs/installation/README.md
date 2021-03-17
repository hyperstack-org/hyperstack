# Installation

The easiest way to install Hyperstack in either a new or existing Rails app is to run installer.

## Pre-Requisites

#### - Rails >= 5.x

[Rails Install Instructions](http://railsinstaller.org/en)

#### - Yarn

For a full system install including webpacker for managing javascript assets you will
need yarn.  To skip adding webpacker use `hyperstack:install:skip-webpack`

[Yarn Install Instructions](https://yarnpkg.com/en/docs/install#mac-stable)

## - Creating a New Rails App

If you don't have an existing Rails app to add Hyperstack to, you can create a new Rails app
with the following command line:

```
bundle exec rails new NameOfYourApp -T
```

To avoid much pain, do not name your app `Application` as this will conflict with all sorts of
things in Rails and Hyperstack.

Once you have created the app cd into the newly created directory.

> The -T option will skip adding minitest directories, as Hyperstack prefers RSpec.

## - Installing HyperStack

* add `gem 'rails-hyperstack', "~> 1.0.alpha1.0"` to your gem file
* run `bundle install`
* run `bundle exec rails hyperstack:install`

> Note: if you want to use the unreleased edge branch your gem specification will be:
>
> ```ruby
> gem 'rails-hyperstack',
>      git: 'git://github.com/hyperstack-org/hyperstack.git',
>      branch: 'edge',
>      glob: 'ruby/*/*.gemspec'
> ```
>

## - Start the Rails app

* `bundle exec foreman start` to start Rails and the Hotloader
* Navigate to `http://localhost:5000/`
