## ReactiveRouter

ReactiveRouter allows you write and use the React Router in Ruby through Opal.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reactive-router'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reactive-router

## Usage

This is simply a DSL wrapper on [react-router](....)

### DSL

The following DSL:

```ruby
route("/", mounts: About, index: Home) do 
  route("about")
  route("inbox") do 
    redirect('messages/:id').to { | params | "/messages/#{params[:id]}" }
  end
  route(mounts: Inbox) do 
    route("messages/:id")
  end
end
```

Is equivilent to this route configuration:

```javascript
const routes = {
  path: '/',
  component: App,
  indexRoute: { component: Dashboard },
  childRoutes: [
    { path: 'about', component: About },
    {
      path: 'inbox',
      component: Inbox,
      childRoutes: [{
        path: 'messages/:id',
        onEnter: ({ params }, replace) => replace(`/messages/${params.id}`)
      }]
    },
    {
      component: Inbox,
      childRoutes: [{
        path: 'messages/:id', component: Message
      }]
    }
  ]
}
```

The basic dsl syntax is designed with the following in mind:

1. Most routes have a path so that is the assumed first argument.
2. Use `mounts` rather than component (reads better?)
3. Convention over configuration, given a path, the component name can be derived.
4. Redirect takes the path, and a block (similar to the JSX DSL)
5. The first param to route can be skipped per the documentation
6. Use standard ruby lower case method names instead of caps (reserve those for components)

The above example does not cover all the possible syntax, here are the other methods and options:

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
| `previous_state` | `:change` | returns the previous state object |
| `replace` | `:change`, `:enter` | pass `replace` a new path |
| `promise` | `:change`, `:enter` | returns a new promise.  multiple calls returns the same promise |

If you return a promise from the `:change` or `:enter` hooks, the transition will wait till the promise is resolved before proceeding.  For simplicity you can call the promise method, but you can also use some other method to define the promise.

The hooks can also be specified as proc values to the `:on_leave`, `:on_enter`, `:on_change` options.

#### multiple component mounting

The `mounts` option can accept a single component, or a hash which will generate a `components` (plural) react-router prop, as in:

`route("groups", mounts: {main: Groups, sidebar: GroupsSidebar})` which is equivalent to:

`{path: "groups", components: {main: Groups, sidebar: GroupsSidebar}}` (json) or

`<Route path="groups" components={{main: Groups, sidebar: GroupsSidebar}} />` JSX

#### The `mounts` and `index` options can also take a `Proc` or be specified as a block

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

#### The index route can be specified as a proc, or via a block

Same deal as mount...

`route("foo").index { ...compute the index or just return a promise... }`

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
class Router < React::Router 
  
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

You will mount this component the usual way (i.e. via `render_component`, `Element#render`, `react_render`, etc) or even by mounting it within a higher level application component.

#### Other router methods:

There are several other methods that can be redefined to modify the routers behavior

#### history

```ruby 
class Router < React::Router
  def history 
  ... return a history object
  end
end
```

#### create_element

`create_element` is passed the component that the router will render, and its params.  Use it to modify behaviors.  

```ruby 
class Router < React::Router
  def create_element(component, params)
    # default behavior is to render the component with params
    component.render params
  end
end
```

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

#### `render` <- needs work

By default the `render` method call the RouterContext component passing in all the router's parameters.

This is primarily for integrating with other libraries that need to participate in rendering before the route components are rendered. It defaults to render={(props) => <RouterContext {...props} />}.

Ensure that you render a <RouterContext> at the end of the line, passing all the props passed to render.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/catprintlabs/reactor-router/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
