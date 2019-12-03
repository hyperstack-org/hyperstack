# Hyperstack Rails Template

**This will create a new Rails app with Webpacker and the current released Hyperstack gems by running the installation template in the edge branch.**

## Prerequisites

+ Linux or Mac system  
  (Android, ChromeOS and Windows are not supported)
+ Ruby on Rails must be installed: https://rubyonrails.org/
+ NodeJS must be installed: https://nodejs.org
+ Yarn must be installed: https://yarnpkg.com/en/docs/install

## Usage

Simply run the command below to create a new Rails app with Hyperstack all configured:

```shell
rails new MyAppName --template=https://rawgit.com/hyperstack-org/hyperstack/edge/install/rails-webpacker.rb
```
Alternatively, if you like, you can also download [the template file](https://rawgit.com/hyperstack-org/hyperstack/edge/install/rails-webpacker.rb) (the part after `--template=`) and read the contents,
it shows how a Hyperstack Rails project differs from a plain Rails project.
The downloaded file can then be referenced from the local filesystem.
```shell
rails new MyAppName --template=rails-webpacker.rb
```

## Start the Rails app

+ Run `foreman start` from a console to start the Ruby on Rails server and Opal HotReloader
+ Navigate to http://localhost:5000

### Tutorial

If you are new to developing an application based on Hyperstack we suggest you follow the [todo tutorial](https://docs.hyperstack.org/tutorial).
