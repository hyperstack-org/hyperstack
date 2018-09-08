Install instructions for the latest lap (lap is hyperloop designation for release candidate):
```
gem "opal-jquery", git: "https://github.com/opal/opal-jquery.git", branch: "master"

gem 'hyperloop', '~> 1.0.0.lap0'
gem 'hyper-spec', '~> 1.0.0.lap0'
```

### testing ruby-hyperloop gems
See, section **Testing Ruby-Hyperloop**
[https://github.com/janbiedermann/dciy](https://github.com/janbiedermann/dciy)


<div class="githubhyperloopheader">

<p align="center">

<a href="http://ruby-hyperloop.io/" alt="Hyperloop" title="Hyperloop">
<img width="350px" src="http://ruby-hyperloop.io/images/hyperloop-github-logo.png">
</a>

</p>

<h2 align="center">The Complete Isomorphic Ruby Framework</h2>

<br>

<a href="http://ruby-hyperloop.io/" alt="Hyperloop" title="Hyperloop">
<img src="http://ruby-hyperloop.io/images/githubhyperloopbadge.png">
</a>

<a href="https://gitter.im/ruby-hyperloop/chat" alt="Gitter chat" title="Gitter chat">
<img src="http://ruby-hyperloop.io/images/githubgitterbadge.png">
</a>

</div>

## Hyperloop GEM

Build interactive Web applications quickly. Hyperloop encourages rapid development with clean, pragmatic design. With developer productivity as our highest goal, Hyperloop takes care of much of the hassle of Web development, so you can focus on innovation and delivering end-user value.

One language. One model. One set of tests. The same business logic and domain models running on the clients and the server. Hyperloop is fully integrated with Rails and also gives you unfettered access to the complete universe of JavaScript libraries (including React) from within your Ruby code. Hyperloop lets you build beautiful interactive user interfaces in Ruby.

Everything has a place in our architecture. Components deliver interactive user experiences, Operations encapsulate business logic, Models magically synchronize data between clients and servers, Policies govern authorization and Stores hold local state. 

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
    * [Getting Started with Hyperloop](http://ruby-hyperloop.io/start)
    * [Hyperloop Guides](http://ruby-hyperloop.io/docs/architecture)
    * [Hyperloop Tutorial](http://ruby-hyperloop.io/tutorials)


## License

Hyperloop is released under the [MIT License](http://www.opensource.org/licenses/MIT).

