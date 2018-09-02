<div class="githubhyperloopheader">

<p align="center">

<a href="http://ruby-hyperloop.org/" alt="Hyperloop" title="Hyperloop">
<img width="350px" src="http://ruby-hyperloop.org/images/hyperloop-github-logo.png">
</a>

</p>

<h2 align="center">The Complete Isomorphic Ruby Framework</h2>

<br>

<a href="http://ruby-hyperloop.org/" alt="Hyperloop" title="Hyperloop">
<img src="http://ruby-hyperloop.org/images/githubhyperloopbadge.png">
</a>

<a href="https://gitter.im/ruby-hyperloop/chat" alt="Gitter chat" title="Gitter chat">
<img src="http://ruby-hyperloop.org/images/githubgitterbadge.png">
</a>

[![Build Status](https://travis-ci.org/ruby-hyperloop/hyper-operation.svg?branch=master)](https://travis-ci.org/ruby-hyperloop/hyper-operation)
[![Gem Version](https://badge.fury.io/rb/hyper-operation.svg)](https://badge.fury.io/rb/hyper-operation)

<p align="center">
<img src="http://ruby-hyperloop.org/images/HyperOperations.png" width="100" alt="Hyper-operation">
</p>

</div>

## Hyper-Operation GEM is part of Hyperloop GEMS family

Build interactive Web applications quickly. Hyperloop encourages rapid development with clean, pragmatic design. With developer productivity as our highest goal, Hyperloop takes care of much of the hassle of Web development, so you can focus on innovation and delivering end-user value.

One language. One model. One set of tests. The same business logic and domain models running on the clients and the server. Hyperloop is fully integrated with Rails and also gives you unfettered access to the complete universe of JavaScript libraries (including React) from within your Ruby code. Hyperloop lets you build beautiful interactive user interfaces in Ruby.

Everything has a place in our architecture. Components deliver interactive user experiences, Operations encapsulate business logic, Models magically synchronize data between clients and servers, Policies govern authorization and Stores hold local state.

**Hyper-Operation** brings Operations which encapsulate business logic. In a traditional MVC architecture, Operations end up either in Controllers, Models or some other secondary construct such as service objects, helpers, or concerns. Here they are first class objects. Their job is to mutate state in the Stores and Models.

## Getting Started

1. Update your Gemfile:

```ruby
#Gemfile

gem 'hyperloop'
```

2. At the command prompt, update your bundle :

        $ bundle update

3. Run the hyperloop install generator:

        $ rails g hyperloop:install

4. Follow the guidelines to start developing your application. You may find
   the following resources handy:
    * [Getting Started with Hyperloop](http://ruby-hyperloop.org/start/components/)
    * [Hyperloop Guides](http://ruby-hyperloop.org/docs/architecture)
    * [Hyperloop Tutorial](http://ruby-hyperloop.org/tutorials)

## Community

#### Getting Help
Please **do not post** usage questions to GitHub Issues. For these types of questions use our [Gitter chatroom](https://gitter.im/ruby-hyperloop/chat) or [StackOverflow](http://stackoverflow.com/questions/tagged/hyperloop).

#### Submitting Bugs and Enhancements
[GitHub Issues](https://github.com/ruby-hyperloop/hyperloop/issues) is for suggesting enhancements and reporting bugs. Before submiting a bug make sure you do the following:
* Check out our [contributing guide](https://github.com/ruby-hyperloop/hyperloop/blob/master/CONTRIBUTING.md) for info on our release cycle.

## License

Hyperloop is released under the [MIT License](http://www.opensource.org/licenses/MIT).
