## HyperRouter

HyperRouter allows you write and use the React Router in Ruby through Opal.

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
      LI { Link("#{params.match[:url]}/rendering") { 'Rendering with React' } }
      LI { Link("#{params.match[:url]}/components") { 'Components' } }
      LI { Link("#{params.match[:url]}/props-v-state") { 'Props v. State' } }
    end
    Route("#{params.match[:url]}/:topic_id", mounts: Topic)
    Route(params.match[:url], exact: true) do
      H3 { 'Please select a topic.' }
    end
  end
end

class Topic < Hyperloop::Router::Component
  render(:div) do
    H3 { params.match[:params][:topic_id] }
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

### BrowserRouter, HashRouter, MemoryRouter, StaticRouter

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
The block will give you the match data passed in as a hash:
```ruby
class MyRouter < Hyperloop::Router
  ...

  route do
    DIV do
      Route('/:name') do |match|
        H1 { "Hello #{match[:params][:foo]}!" }
      end
    end
  end
end
```

It is recommended to inherit from `Hyperloop::Router::Component` for components mounted by routes.
This automatically sets the `match` params, and gives you access to the Route method and more.
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
    H1 { "Hello #{params.match[:params][:foo]}!" }
    Route(params.match[:url], exact: true) do
      H2 { 'What would you like to do?' }
    end
    Route("#{params.match[:url]}/:activity", mounts: Activity)
  end
end

class Activity < Hyperloop::Router::Component
  render(DIV) do
    H2 { params.match[:params][:activity] }
  end
end
```

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
        H1 { "Will #{match[:params][:name]} eat all the chickens?" }
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
                match && match[:params][:name] && match[:params][:name] =~ /Martell/
              })

      Route('/', exact: true) { H1() }
      Route('/:name') do |match|
        H1 { "Will #{match[:params][:name]} eat all the chickens?" }
      end
    end
  end
end
```

#### enter / leave / change transition hooks

for adding an onEnter or onLeave hook you would say:

```ruby
route("foo").on(:leave) { | t | ... }.on(:enter) { | t |.... }
```
which follows the react.rb event handler convention.

A `TransitionContext` object will be passed to the handler, which has the following methods:

| method | available on | description |
|-----------|------------------|-----------------|
| `next_state` | `:change`, `:enter` | returns the next state object |
| `prev_state` | `:change` | returns the previous state object |
| `replace` | `:change`, `:enter` | pass `replace` a new path |
| `promise` | `:change`, `:enter` | returns a new promise.  multiple calls returns the same promise |

If you return a promise from the `:change` or `:enter` hooks, the transition will wait till the promise is resolved before proceeding.  For simplicity you can call the promise method, but you can also use some other method to define the promise.

The hooks can also be specified as proc values to the `:on_leave`, `:on_enter`, `:on_change` options.

#### multiple component mounting

The `mounts` option can accept a single component, or a hash which will generate a `components` (plural) react-router prop, as in:

`route("groups", mounts: {main: Groups, sidebar: GroupsSidebar})` which is equivalent to:

`{path: "groups", components: {main: Groups, sidebar: GroupsSidebar}}` (json) or

`<Route path="groups" components={{main: Groups, sidebar: GroupsSidebar}} />` JSX

#### The `mounts` option can also take a `Proc` or be specified as a block

The proc is passed a TransitionContext (see **Hooks** above) and may either return a react component to be mounted, or return a promise.  If a promise is returned the transition will wait till the promise is either resolved with a component, or rejected.

`route("courses/:courseId", mounts: -> () { Course }`

is the same as:

```jsx
<Route path="courses/:courseId" getComponent={(nextState, cb) => {cb(null, Course)}} />
```

Also instead of a proc, a block can be specified with the `mounts` method:

`route("courses/:courseId").mounts { Course }`

Which generates the same route as the above.

More interesting would be something like this:

```ruby
route("courses/:id").mounts do | ct |
  HTTP.get("validate-user-access/courses/#{ct.next_state[:id]}").then {  Course }
end
```

*Note that the above works because of promise chaining.*

You can use the `mount` method multiple times with different arguments as an alternative to passing the the `mount` option a hash:

`route("foo").mount(:baz) { Comp1 }.mount(:bar) { Comp2 }.mount(:bomb)`

Note that if no block is given (as in `:bomb` above) the component name will be inferred from the argument (`Bomb` in this case.)

#### The index component can be specified as a proc

Same deal as mount...

`route("foo", index: -> { MyIndex })`

#### The index method

Instead of specifying the index component as a param to the parent route, it can be specified as a child using the
index method:

```ruby
route("/", mounts: About, index: Home) do
  index(mounts: MyIndex)
  route("about")
  route("privacy-policy")
end
```

This is useful because the index method has all the features of a route except that it does not take a path or children.

#### The `redirect` options

with static arguments:

`redirect("/from/path/spec", to: "/to/path/spec", query: {q1: 123, q2: :abc})`

the `:to` and `:query` options can be Procs which will receive the current state.

Or you can specify the `:to` an `:query` options with blocks:

`redirect("/from/path/spec/:id").to { |curr_state| "/to/path/spec/#{current_state[:id]}"}.query { {q1: 12} }`

#### The `index_redirect` method

just like `redirect` without the first arg: `index_redirect(to: ... query: ...)`

### The Router Component

A router is defined as a subclass of `React::Router` which is itself a `React::Component::Base`.

```ruby
class Components::Router < React::Router
  def routes # define your routes (there is no render method)
    route("/", mounts: About, index: Home) do
      route("about")
      route("inbox") do
        redirect('messages/:id').to { | params | "/messages/#{params[:id]}" }
      end
      route(mounts: Inbox) do
        route("messages/:id")
      end
    end
  end  
end
```
#### Mounting your Router
You will mount this component the usual way (i.e. via `render_component`, `Element#render`, `react_render`, etc) or even by mounting it within a higher level application component.

```ruby
class Components::App < React::Component::Base
  render(DIV) do
    Application::Nav()
    MAIN do
      Router()
    end
  end
end
```

#### navigating

Create links to your routes with `Router::Link`
```ruby
#Application::Nav
  LI.nav_link { TestRouter::Link("/") { "Home" } }
  LI.nav_link { TestRouter::Link("/about") { "About" } }
  params.messsages.each do |msg|
    LI.nav_link { TestRouter::Link("/inbox/messages/#{msg.id}") { msg.title } }
  end
```

Additionally, you can manipulate the history with by passing JS as so
```ruby
# app/views/components/app_links.rb
class Components::AppLinks
  class << self
    if RUBY_ENGINE == 'opal'
      def inbox
        `window.ReactRouter.browserHistory.push('/inbox');`
      end
      def message(id)
        `window.ReactRouter.browserHistory.push('/messages/#{id}');`
      end
    end
  end
end
```


#### Other router hooks:

There are several other methods that can be redefined to modify the routers behavior

#### history

```ruby
class Router < React::Router
  def history
  ... return a history object
  end
end
```

The two standard history objects are predefined as `browser_history` and `hash_history` so you can say:

```ruby
...
  def history
    browser_history
  end
```

or just

```ruby
...
  alias_method :history :browser_history
```

#### create_element

`create_element` (if defined) is passed the component that the router will render, and its params.  Use it to intercept, inspect and/or modify the component behavior.

`create_element` can return any of these values:

+ Any falsy value: indicating that rendering should continue with no modification to behavior.
+ A `React::Element`, or a native `React.Element` which will be used for rendering.
+ Any truthy value: indicating that a new Element should be created using the (probably modified) params

```ruby
class Router < React::Router
  def create_element(component, component_params)
    # add the param :time_stamp to each element as its rendered
    React.create_element(component, component_params.merge(time_stamp: Time.now))
  end
end
```

The above could be simplified to:

```ruby
...
  def create_element(component, component_params)
    component_params[:time_stamp] = Time.now
  end
```

Just make sure that you return a truthy value otherwise it will ignore any changes to component or params.

Or if you just wanted some kind of logging:

```ruby
...
  def create_element(component, component_params)
    puts "[#{Time.now}] Rendering: #{component.name}" # puts returns nil, so we are jake mate
  end
```

The component_params will always contain the following keys as native js objects, and they must stay native js objects:

+ `children`
+ `history`
+ `location`
+ `params`
+ `route`
+ `route_params`
+ `routes`

We will try to get more fancy with a later version of reactrb-router ;-)

#### `stringify_query(params_hash)` <- needs work

The method used to convert an object from <Link>s or calls to transitionTo to a URL query string.

```ruby
class Router < React::Router
  def stringify_query(params_hash)
    # who knows doc is a little unclear on this one...is it being passed the full params_hash or just
    # the query portion.... we shall see...
  end
end
```

#### `parse_query_string(string)` <- needs work

The method used to convert a query string into the route components's param hash

#### `on_error(data)`

While the router is matching, errors may bubble up, here is your opportunity to catch and deal with them. Typically these will come when promises are rejected (see the DSL above for returning promises to handle async behaviors.)

#### `on_update`

Called whenever the router updates its state in response to URL changes.

#### `render`

A `Router` default `render` looks like this:

```ruby
  def render
    # Router.router renders the native router component
    Router.router(build_params)
  end
```


This is primarily for integrating with other libraries that need to participate in rendering before the route components are rendered. It defaults to render={(props) => <RouterContext {...props} />}.

Ensure that you render a <RouterContext> at the end of the line, passing all the props passed to render.

### React::Router::Component

The class React::Router::Component is a subclass of React::Component::Base that predefines the params that the router will be passing in to your component.  This includes

`params.location`

The current location.

`params.params`

The dynamic segments of the URL.

`params.route`

The route that rendered this component.

`params.route_params`

The subset of `params.params` that were directly specified in this component's route. For example, if the route's path is `users/:user_id` and the URL is /users/123/portfolios/345 then `params.route_params` will be `{user_id: '123'}`, and `params.params` will be `{user_id: '123', portfolio_id: 345}`.

## Development

`bundle exec rake` runs test suite

## Contributing

1. Fork it ( https://github.com/ruby-hyperloop/reactrb-router/tree/hyper-router/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
