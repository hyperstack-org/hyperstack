## Prerequisites

#### Rails

Hyperstack is currently tested on Rails ~> 5.0 and ~> 6.0.
>If you are on Rails 4.0 it might be time to upgrade, but that said you probably can manually install Hyperstack on Rails 4.0 and get it working.

[Rails Install Instructions](http://railsinstaller.org/en)

#### Yarn

For a full system install including webpacker for managing javascript assets you will
need yarn.  To skip adding webpacker use `hyperstack:install:skip-webpack` when installing Hyperstack.

[Yarn Install Instructions](https://yarnpkg.com/en/docs/install#mac-stable)

#### Database

To fully utilize Hyperstack's capabilities you will be need an SQL database that has an ActiveRecord adapter. If you have a choice we have found Postgresql works best (and it also deploys to Heroku without issue.)  If you are new to Rails, then the default Sqlite database (which rails will install) will work fine.
> Why don't we support NoSql databases?  The biggest reasons are security and effeciency.  Hyperstack access-policies are based on known table names and attributes and after-commit hooks.  Keep in mind that modern DBs support the json and jsonb attribute types allowing you to add arbitrary json based data to your database.

### Creating a New Rails App

If you don't have an existing Rails app you can create a new Rails app
with the following command line:

```
rails new NameOfYourApp -T
```

To avoid much pain do not name your app `Application` as this will conflict with all sorts of
things in Rails and Hyperstack.

Once you have created the app cd into the newly created directory.

> The -T option will skip adding minitest directories as Hyperstack prefers RSpec.  However if you have an existing app with minitest that is okay too.
