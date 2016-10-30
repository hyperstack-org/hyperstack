# hyper-react

[![Join the chat at https://gitter.im/reactrb/chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/reactrb/chat?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/reactrb/reactrb.svg?branch=master)](https://travis-ci.org/reactrb/reactrb)
[![Code Climate](https://codeclimate.com/github/reactrb/reactrb/badges/gpa.svg)](https://codeclimate.com/github/reactrb/reactrb)
[![Gem Version](https://badge.fury.io/rb/reactrb.svg)](https://badge.fury.io/rb/reactrb)

**hyper-react is an [Opal Ruby](http://opalrb.org) wrapper of
[React.js library](https://facebook.github.io/react)**.

It lets you write reactive UI components, with Ruby's elegance using the tried
and true React.js engine. :heart:

Visit [** ruby-hyperloop.io**](http://ruby-hyperloop.io) for the full story.

### Important: `react.rb`, `reactive-ruby` and `reactrb` gems are **deprecated.**. See [**UPGRADING**](UPGRADING.md) for details.

## Installation

Install the gem, or load the js library

1. Add `gem 'hyper-react'` to your **Gemfile**
2. Or `gem install hyper-react`
3. Or install (or load via cdn) from [reactrb-express.js](http://github.com/reactrb/reactrb-express)

For gem installation it is highly recommended to read the [getting started](http://ruby-hyperloop.io/get_started/) and [installation](http://ruby-hyperloop.io/installation/) guides at [ruby-hyperloop.io.](http://ruby-hyperloop.io)

## Quick Overview

A component is a plain ruby class with a `#render` method defined.

```ruby
class HelloMessage
  def render
    React.create_element("div") { "Hello World!" }
  end
end

puts React.render_to_static_markup(React.create_element(HelloMessage))

# => '<div>Hello World!</div>'
```

### React::Component

You can simply include `React::Component` to get the power of a complete DSL to generate html markup, event handlers and it also provides a full set of class macros to define states, parameters, and lifecycle callbacks.

As events occur, components update their state, which causes them to rerender, and perhaps pass new parameters to lower level components, thus causing them to rerender.

```ruby
class HelloWorld < React::Component::Base
  param :time, type: Time
  render do
    p do
      span { "Hello, " }
      input(type: :text, placeholder: "Your Name Here")
      span { "! It is #{params.time}"}
    end
  end
end

every(1) do
  Element["#example"].render do
    HelloWorld(time: Time.now)
  end
end
```

hyper-react components are *isomorphic* (or *univeral*) meaning they can run on the server as well as the client.

hyper-react integrates well with Rails, Sinatra, and simple static sites, and can be added to existing web pages very easily.

Under the hood the actual work is effeciently done by the [React.js](https://facebook.github.io/react) engine.


## Why ?

+ *Single Language:*  Use Ruby everywhere, no JS, markup languages, or JSX
+ *Powerful DSL:* Describe HTML and event handlers with a minimum of fuss
+ *Ruby Goodness:* Use all the features of Ruby to create reusable, maintainable UI code
+ *React Simplicity:* Nothing is taken away from the React.js model
+ *Enhanced Features:* Enhanced parameter and state management and other new features
+ *Plays well with Others:* Works with other frameworks, React.js components, Rails, Sinatra and static web pages

## Problems, Questions, Issues

+ [Stack Overflow](http://stackoverflow.com/questions/tagged/react.rb) tag `react.rb` for specific problems.
+ [Gitter.im](https://gitter.im/reactrb/chat) for general questions, discussion, and interactive help.
+ [Github Issues](https://github.com/reactrb/reactrb/issues) for bugs, feature enhancements, etc.


## Roadmap

Version 0.10.x **will not be** 100% backward compatible with 0.3.0 (`react.rb`) or 0.7.x (`reactive-ruby`).

Please let us know either at [Gitter.im](https://gitter.im/reactrb/chat) or [via an issue](https://github.com/reactrb/reactrb/issues) if you have specific concerns with the upgrade from 0.3.0 to 0.10.x.

## Developing

`git clone` the project.

To play with some live examples, refer to https://github.com/reactrb/reactrb-examples.

Note that these are very simple examples, for the purpose of showing how to configure the gem in various server environments.  For more examples and information see [ruby-hyperloop.io.](http://ruby-hyperloop.io)

## Testing

1. Run `bundle exec rake test_app` to generate a dummy test app.
2. `bundle exec appraisal install` to generate separate gemfiles for different environments.
2. `bundle exec appraisal opal-0.9-react-15 rake` to run test for opal-0.9 & react-v0.15.

## Contributions

This project is still in early stage, so discussion, bug reports and PRs are
really welcome :wink:.


## License

In short, hyper-react is available under the MIT license. See the LICENSE file for
more info.
