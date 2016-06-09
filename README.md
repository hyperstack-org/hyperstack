# Reactrb / Reactive-Ruby

[![Join the chat at https://gitter.im/reactrb/chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/reactrb/chat?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/reactrb/reactrb.svg)](https://travis-ci.org/reactrb/reactrb)
[![Code Climate](https://codeclimate.com/github/reactrb/reactrb/badges/gpa.svg)](https://codeclimate.com/github/reactrb/reactrb)
[![Gem Version](https://badge.fury.io/rb/reactrb.svg)](https://badge.fury.io/rb/reactrb)

**Reactrb is an [Opal Ruby](http://opalrb.org) wrapper of
[React.js library](http://facebook.github.io/reactrb/)**.

It lets you write reactive UI components, with Ruby's elegance using the tried
and true React.js engine. :heart:

[**Visit reactrb.org For The Full Story**](http://reactrb.org)

### Important: `react.rb` and `reactive-ruby` gems are **deprecated.** Please [read this!](#upgrading-to-reactrb)

## Installation

Install the gem, or load the js library

+ add `gem 'reactrb'` to your gem file or
+ `gem install reactrb` or
+ install (or load via cdn) [inline-reactrb.js](http://github.com/reactrb/inline-reactrb)

For gem installation it is highly recommended to read [the getting started section at reactrb.org](http://reactrb.org/docs/getting-started.html)

## Quick Overview

Reactrb components are ruby classes that inherit from `React::Component::Base` or include `React::Component`.

`React::Component` provides a complete DSL to generate html and event handlers, and has full set of class macros to define states, parameters, and lifecycle callbacks.

Each react component class has a render method that generates the markup for that component.

Each react component class defines a new tag-method in the DSL that works just like built-in html tags, so react components can render other react components.

As events occur, components update their state, which causes them to rerender, and perhaps pass new parameters to lower level components, thus causing them to rerender.  

Under the hood the actual work is effeciently done by the [React.js](http://facebook.github.io/reactrb/) engine.

Reactrb components are *isomorphic* meaning they can run on the server as well as the client.  This means that the initial expansion of the component tree to markup is done server side, just like ERB, or HAML templates.   Then the same code runs on the client and will respond to any events.   

Reactrb integrates well with Rails, Sinatra, and simple static sites, and can be added to existing web pages very easily, or it can be used to deliver complete websites.

## Why ?

+ *Single Language:*  Use Ruby everywhere, no JS, markup languages, or JSX
+ *Powerful DSL:* Describe HTML and event handlers with a minimum of fuss
+ *Ruby Goodness:* Use all the features of Ruby to create reusable, maintainable UI code
+ *React Simplicity:* Nothing is taken away from the React.js model
+ *Enhanced Features:* Enhanced parameter and state management and other new features
+ *Plays well with Others:* Works with other frameworks, React.js components, Rails, Sinatra and static web pages

# Problems, Questions, Issues

+ [Stack Overflow](http://stackoverflow.com/questions/tagged/react.rb) tag `react.rb` for specific problems.
+ [Gitter.im](https://gitter.im/reactrb/chat) for general questions, discussion, and interactive help.
+ [Github Issues](https://github.com/reactrb/reactrb/issues) for bugs, feature enhancements, etc.


# Upgrading to Reactrb

The original gem `react.rb` was superceeded by `reactive-ruby`, which has had over 15,000 downloads.  This name has now been superceeded by `reactrb` (see #144 for detailed discussion on why.)

Going forward the name `reactrb` will be used consistently as the organization name, the gem name, the domain name, the twitter handle, etc.

The first initial version of `reactrb` is 0.8.x.  

It is very unlikely that there will be any more releases of the `reactive-ruby` gem, so users should upgrade to `reactrb`.

There are no syntactic or semantic breaking changes between `reactrb` v 0.8.x and
previous versions, however the `reactrb` gem does *not* include the react-js source as previous versions did.  This allows you to pick the react js source compatible with other gems and react js components you may be using.

To upgrade, replace `reactive-ruby` with `reactrb`, both in your Gemfile, and in any `requires` in your code.   You will also need to require react-js as this is no longer included in the gem.  

If you are using react-rails then simply find anyplace where you `require 'reactrb'` and immediately before this do a `require 'react'` which will load the compatible react js file.

If you are using webpack then add `react` to your manifest.

If you are not using react-rails then find where you `require 'reactrb'` and immediately before this do a `require 'react-latest'` (or 'react-v13', 'react-v14' or 'react-v15')

# Roadmap

Upcoming will be an 0.9.x release which will deprecate a number of features and DSL elements.  [click for detailed feature list](https://github.com/reactrb/reactrb/milestones/0.9.x)

Version 0.10.x **will not be** 100% backward compatible with 0.3.0 (`react.rb`) or 0.7.x (`reactive-ruby`) so its very important to begin your upgrade process now by switching to `reactrb` now.

Please let us know either at [Gitter.im](https://gitter.im/reactrb/chat) or [via an issue](https://github.com/reactrb/reactrb/issues) if you have specific concerns with the upgrade from 0.3.0 to 0.10.x.

## Developing

`git clone` the project.

To play with some live examples cd to the project directory then

2. `cd example/examples`
2. `bundle install`
3. `bundle exec rackup`
4. Open `http://localhost:9292`

or

1. `cd example/rails-tutorial`
2. `bundle install`
3. `bundle exec rails s`
4. Open `http://localhost:3000`

or

1. `cd example/sinatra-tutorial`
2. `bundle install`
3. `bundle exec rackup`
4. Open `http://localhost:9292`

Note that these are very simple examples, for the purpose of showing how to configure the gem in various server environments.  For more  examples and information see [reactrb.org.](http://reactrb.org)

## Testing

1. Run `bundle exec rake test_app` to generate a dummy test app.
2. `bundle exec rake`

## Contributions

This project is still in early stage, so discussion, bug reports and PRs are
really welcome :wink:.   


## License

In short, Reactrb is available under the MIT license. See the LICENSE file for
more info.
