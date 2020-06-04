# Client-side Routing

HyperRouter is a DSL wrapper for [ReactRouter v4.x](https://github.com/ReactTraining/react-router) to provide client-side routing for Single Page Applications (SPA).

## Usage

```ruby
class AppRouter
  include Hyperstack::Component
  include Hyperstack::Router::Helpers
  include Hyperstack::Router

  render(DIV) do
    UL do
      LI { Link('/') { 'Home' } }
      LI { Link('/about') { 'About' } }
    end
    Route('/', exact: true, mounts: Home)
    Route('/about', mounts: About)
  end
end

class Home
  include Hyperstack::Component
  render(DIV) do
    H2 { 'Home' }
  end
end
```

## DSL

### Router

This is the Router module which you include in your top level component:

```ruby
class MyRouter
  include Hyperstack::Component
  include Hyperstack::Router
end
```

With the base Router class, you can also specify the history you want to use.

This can be done either using a macro:

```ruby
class MyRouter
  include Hyperstack::Component
  include Hyperstack::Router

  history :browser  # this is the default option if no other is specified
end
```

The macro accepts three options: `:browser`, `:hash`, or `:memory`.

Or by defining the `history` method:

```ruby
class MyRouter
  include Hyperstack::Component
  include Hyperstack::Router

  def history
    self.class.browser_history
  end
end
```

### Rendering a Router

Use the `render` macro as normal. Note you cannot redefine the `render` instance method in a Router componenent

```ruby
class MyRouter
  ...

  render(DIV) do
    H1 { 'Hello world!' }
  end
end
```

### Routes

Routes are defined with special pseudo components you call inside the router/components. The router determines which of the routes to actually mount based on the current URL.

```ruby
class MyRouter
  ...

  render(DIV) do
    Route('/', mounts: HelloWorld)
  end
end

class HelloWorld
  render do
    H1 { 'Hello world!' }
  end
end
```

The `Route` method takes a url path, and these options:

* `mounts: Component` The component you want to mount when routed to
* `exact: Boolean` When true, the path must match the location exactly
* `strict: Boolean` When true, the path will only match if the location and path **both** have/don't have a trailing slash

The `Route` method can also take a block instead of the `mounts` option.

```ruby
class MyRouter
  ...

  render(DIV) do
    Route('/', exact: true) do
      H1 { 'Hello world!' }
    end
  end
end
```

The block will be given the match, location, and history data:

```ruby
class MyRouter
  ...

  render(DIV) do
    Route('/:name') do |match, location, history|
      H1 { "Hello #{match.params[:name]} from #{location.pathname}, click me to go back!" }
        .on(:click) { history.go_back }
    end
  end
end
```

* The `Hyperstack::Router::Helpers` is useful for components mounted by the router.
* This automatically sets the `match`, `location`, and `history` params,

  and also gives you instance methods with those names.

* You can use either `params.match` or just `match`.

  and gives you access to the `Route` method and more.

* This allows you to create inner routes as you need them.

```ruby
class MyRouter
  include Hyperstack::Component
  include Hyperstack::Router::Helpers
  include Hyperstack::Router

  render(DIV) do
    Route('/:name', mounts: Greet)
  end
end

class Greet
  include Hyperstack::Component
  include Hyperstack::Router::Helpers

  render(DIV) do
    H1 { "Hello #{match.params[:foo]}!" }
    Route(match.url, exact: true) do
      H2 { 'What would you like to do?' }
    end
    Route("#{match.url}/:activity", mounts: Activity)
  end
end

class Activity
  include Hyperstack::Component
  include Hyperstack::Router::Helpers
  include Hyperstack::Router

  render(DIV) do
    H2 { params.match.params[:activity] }
  end
end
```

Normally routes will **always** render alongside sibling routes that match as well.

```ruby
class MyRouter
  ...

  render(DIV) do
    Route('/goodbye', mounts: Goodbye)
    Route('/:name', mounts: Greet)
  end
end
```

### Switch

Going to `/goodbye` would match `/:name` as well and render `Greet` with the `name` param with the value 'goodbye'. To avoid this behavior and only render one matching route at a time, use a `Switch` component.

```ruby
class MyRouter
  ...

  render(DIV) do
    Switch do
      Route('/goodbye', mounts: Goodbye)
      Route('/:name', mounts: Greet)
    end
  end
end
```

Now, going to `/goodbye` would match the `Goodbye` route first and only render that component.

### Links

Links are provided by both the `Hyperstack::Router` and `Hyperstack::Router::Helper` modules.

The `Link` method takes a url path, and these options:

* `search: String` adds the specified string to the search query
* `hash: String` adds the specified string to the hash location

  it can also take a block of children to render inside it.

```ruby
class MyRouter
  ...

  render(DIV) do
    Link('/Gregor Clegane')

    Route('/', exact: true) { H1() }
    Route('/:name') do |match|
      H1 { "Will #{match.params[:name]} eat all the chickens?" }
    end
  end
end
```

### NavLinks

NavLinks are the same as Links, but will add styling attributes when it matches the current url

* `active_class: String` adds the class to the link when the url matches
* `active_style: String` adds the style to the link when the url matches
* `active: Proc` A proc that will add extra logic to determine if the link is active

```ruby
class MyRouter
  ...

  render(DIV) do
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
```

### Pre-rendering

Pre-rendering is automatically taken care for you under the hood.

## Setup

To setup HyperRouter:

* Install the gem
* Your page should render your router as its top-level-component \(first component to be rendered on the page\) - in the example below this would be `AppRouter`
* You will need to configure your server to route all unknown routes to the client-side router \(Rails example below\)

### With Rails

Assuming your router is called `AppRouter`, add the following to your `routes.rb`

```ruby
root 'Hyperstack#AppRouter' # see note below
match '*all', to: 'Hyperstack#AppRouter', via: [:get] # this should be the last line of routes.rb
```

Note:

`root 'Hyperstack#AppRouter'` is shorthand which will automagically create a Controller, View and launch `AppRouter` as the top-level Component. If you are rendering your Component via your own COntroller or View then ignore this line.

### Example

Here is the basic JSX example that is used on the [react-router site](https://reacttraining.com/react-router/)

```jsx
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

And here is the same example in Hyperstack:

```ruby
class BasicExample
  include Hyperstack::Component
  include Hyperstack::Router::Helpers
  include Hyperstack::Router

  render(DIV) do
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

class Home
  include Hyperstack::Component
  include Hyperstack::Router::Helpers

  render(DIV) do
    H2 { 'Home' }
  end
end

class About  
  include Hyperstack::Component
  include Hyperstack::Router::Helpers

  render(:div) do
    H2 { 'About' }
  end
end

class Topics
  include Hyperstack::Component
  include Hyperstack::Router::Helpers

  render(DIV) do
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

class Topic
  include Hyperstack::Component
  include Hyperstack::Router::Helpers

  render(:div) do
    H3 { match.params[:topic_id] }
  end
end
```
