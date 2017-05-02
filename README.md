<p align="center">
  <a href="http://ruby-hyperloop.io/" alt="Hyperloop" title="Hyperloop">
    <img src="https://github.com/ruby-hyperloop/ruby-hyperloop.io/blob/sprint/source/source/images/HyperRouter.png" width="150px"/>
  </a>
 </p>

<h1 align="center">
  HyperRouter
</h1>

<p align="center">
  HyperRouter allows you write and use the React Router in Ruby through Opal.
</p>


## Installation

Add this line to your application's Gemfile:
```ruby
gem 'hyper-router'
```
Or execute:
```bash
gem install hyper-router
```

Then add this to your components.rb:
```ruby
require 'hyper-router'
```

### Using the included source
Add this to your component.rb:
```ruby
require 'hyper-router/react-router-source'
require 'hyper-router'
```

### Using with NPM/Webpack
react-router has now been split into multiple packages, so make sure they are all installed
```bash
npm install react-router react-router-dom history --save
```

Add these to your webpack js file:
```javascript
ReactRouter = require('react-router')
ReactRouterDOM = require('react-router-dom')
History = require('history')
```

## Usage

This is simply a DSL wrapper on [react-router](https://github.com/ReactTraining/react-router)

## Warning!!
The folks over at react-router have gained a reputation for all their API rewrites, so with V4 we have made some changes to follow.
This version is **incompatible** with previous versions' DSL.

### DSL

Here is the basic example that is used on the [react-router site](https://reacttraining.com/react-router/)

```javascript
import React from 'react'
import {
  BrowserRouter as Router,
  Route,
  Link
} from 'react-router-dom'

const BasicExample = () => (
  <Router>
    <div>
      <ul>
        <li><Link to="/">Home</Link></li>
        <li><Link to="/about">About</Link></li>
        <li><Link to="/topics">Topics</Link></li>
      </ul>

      <hr/>

      <Route exact path="/" component={Home}/>
      <Route path="/about" component={About}/>
      <Route path="/topics" component={Topics}/>
    </div>
  </Router>
)

const Home = () => (
  <div>
    <h2>Home</h2>
  </div>
)

const About = () => (
  <div>
    <h2>About</h2>
  </div>
)

const Topics = ({ match }) => (
  <div>
    <h2>Topics</h2>
    <ul>
      <li><Link to={`${match.url}/rendering`}>Rendering with React</Link></li>
      <li><Link to={`${match.url}/components`}>Components</Link></li>
      <li><Link to={`${match.url}/props-v-state`}>Props v. State</Link></li>
    </ul>

    <Route path={`${match.url}/:topicId`} component={Topic}/>
    <Route exact path={match.url} render={() => (
      <h3>Please select a topic.</h3>
    )}/>
  </div>
)

const Topic = ({ match }) => (
  <div>
    <h3>{match.params.topicId}</h3>
  </div>
)

export default BasicExample
```

Here is what it looks like for us:
```ruby
class BasicExample < Hyperloop::Router
  history :browser

  route do
    DIV do
      UL do
        LI { Link('/') { 'Home' } }
        LI { Link('/about') { 'About' } }
        LI { Link('/topics') { 'Topics' } }
      end

      Route('/', exact: true, mounts: Home)
      Route('/about', mounts: About)
      Route('/topics', mounts: Topics)
    end
  end
end

class Home < Hyperloop::Router::Component
  render(:div) do
    H2 { 'Home' }
  end
end

class About < Hyperloop::Router::Component
  render(:div) do
    H2 { 'About' }
  end
end

class Topics < Hyperloop::Router::Component
  render(:div) do
    H2 { 'Topics' }
    UL() do
      LI { Link("#{match.url}/rendering") { 'Rendering with React' } }
      LI { Link("#{match.url}/components") { 'Components' } }
      LI { Link("#{match.url}/props-v-state") { 'Props v. State' } }
    end
    Route("#{match.url}/:topic_id", mounts: Topic)
    Route(match.url, exact: true) do
      H3 { 'Please select a topic.' }
    end
  end
end

class Topic < Hyperloop::Router::Component
  render(:div) do
    H3 { match.params[:topic_id] }
  end
end
```

Since react-router migrated back to everything being a component,
this makes the DSL very easy to follow if you have already used react-router v4.

### Router

This is the base Router class, it can either be inherited or included:
```ruby
class MyRouter < Hyperloop::Router
end

class MyRouter < React::Component::Base
  include Hyperloop::Router::Base
end
```

With the base Router class, you must specify the history you want to use.

This can be done either using a macro:
```ruby
class MyRouter < Hyperloop::Router
  history :browser
end
```
The macro accepts three options: `:browser`, `:hash`, or `:memory`.

Or defining the `history` method:
```ruby
class MyRouter < Hyperloop::Router
  def history
    self.class.browser_history
  end
end
```

### BrowserRouter, HashRouter, MemoryRouter

Using one of these classes automatically takes care of the history for you,
so you don't need to specify one.
They also can be used by inheritance or inclusion:

```ruby
class MyRouter < Hyperloop::HashRouter
end

class MyRouter < React::Component::Base
  include Hyperloop::Router::Hash
end
```

### StaticRouter

Static router is a little different, since it doesn't actually have a history.
These are used under-the-hood for any other Router during prerendering.
To use a path with a StaticRouter, with the macro `initial_path`.
This acts the same as `prerender_path` for other routers.

```ruby
class MyRouter < Hyperloop::StaticRouter
  initial_path :current_path

  route do
    DIV do
      Route('/:name', mounts: Greet)
    end
  end
end
```

### Rendering a Router

To render children/routes use the `route` macro, it is the equivalent to `render` of a component.
```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      H1 { 'Hello world!' }
    end
  end
end
```


### Routes

Routes are no longer defined separately, but are just components you call inside the router/components.

```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Route('/', mounts: HelloWorld)
    end
  end
end

class HelloWorld < React::Component::Base
  render do
    H1 { 'Hello world!' }
  end
end
```

The `Route` method takes a url path, and these options:
- `mounts: Component` The component you want to mount when routed to
- `exact: Boolean` When true, the path must match the location exactly
- `strict: Boolean` When true, the path will only match if the location and path **both** have/don't have a trailing slash
It can also take a block instead of the `mounts` option.

```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Route('/', exact: true) do
        H1 { 'Hello world!' }
      end
    end
  end
end
```
The block will give you the match, location, and history data:
```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Route('/:name') do |match, location, history|
        H1 { "Hello #{match.params[:foo]} from #{location.pathname}, click me to go back!" }
          .on(:click) { history.go_back }
      end
    end
  end
end
```

It is recommended to inherit from `Hyperloop::Router::Component` for components mounted by routes.
This automatically sets the `match`, `location`, and `history` params,
and also gives you instance methods with those names.
You can use either `params.match` or just `match`.
and gives you access to the Route method and more.
This allows you to create inner routes as you need them.
```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Route('/:name', mounts: Greet)
    end
  end
end

class Greet < Hyperloop::Router::Component
  render(DIV) do
    H1 { "Hello #{match.params[:foo]}!" }
    Route(match.url, exact: true) do
      H2 { 'What would you like to do?' }
    end
    Route("#{match.url}/:activity", mounts: Activity)
  end
end

class Activity < Hyperloop::Router::Component
  render(DIV) do
    H2 { params.match.params[:activity] }
  end
end
```

Routes will **always** render alongside sibling routes that match as well.

```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Route('/goodbye', mounts: Goodbye)
      Route('/:name', mounts: Greet)
    end
  end
end
```

### Switch

Going to `/goodbye` would match `/:name` as well and render `Greet` with the `name` param with the value 'goodbye'.
To avoid this behavior and only render one matching route at a time, use a `Switch` component.

```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Switch do
        Route('/goodbye', mounts: Goodbye)
        Route('/:name', mounts: Greet)
      end
    end
  end
end
```

Now, going to `/goodbye` would match the `Goodbye` route first and only render that component.

### Links

Links are available to Routers, classes that inherit from `HyperLoop::Router::Component`,
or by including `Hyperloop::Router::ComponentMethods`.

The `Link` method takes a url path, and these options:
- `search: String` adds the specified string to the search query
- `hash: String` adds the specified string to the hash location
It can also take a block of children to render inside it.
```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Link('/Gregor Clegane')

      Route('/', exact: true) { H1() }
      Route('/:name') do |match|
        H1 { "Will #{match.params[:name]} eat all the chickens?" }
      end
    end
  end
end
```

### NavLinks

NavLinks are the same as Links, but will add styling attributes when it matches the current url
- `active_class: String` adds the class to the link when the url matches
- `active_style: String` adds the style to the link when the url matches
- `active: Proc` A proc that will add extra logic to determine if the link is active
```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      NavLink('/Gregor Clegane', active_class: 'active-link')
      NavLink('/Rodrik Cassel', active_style: { color: 'grey' })
      NavLink('/Oberyn Martell',
              active: ->(match, location) {
                match && match.params[:name] && match.params[:name] =~ /Martell/
              })

      Route('/', exact: true) { H1() }
      Route('/:name') do |match|
        H1 { "Will #{match.params[:name]} eat all the chickens?" }
      end
    end
  end
end
```

### Pre-rendering

Pre-rendering has been made extremely simple in this new version.
Under the hood a StaticRouter is used whenever a Router component is prerendering.
To prerender correctly though you will need to give it the current path.
Since there is no DOM, you must pass in the current path from your controller/view as a param.
There is a special param macro called `prerender_path`,
which still acts as a normal param but will use that param as the current path in prerendering.

```ruby
class MyController < ApplicationController
  def show
    render component: 'MyRouter', props: { current_path: request.path }
  end
end

class MyRouter < Hyperloop::Router
  prerender_path :current_path

  route do
    DIV do
      Route('/:name', mounts: Greet)
    end
  end
end
```


## Development

`bundle exec rake` runs test suite

## Contributing

1. Fork it ( https://github.com/ruby-hyperloop/reactrb-router/tree/hyper-router/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
