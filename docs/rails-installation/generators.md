## Hyperstack Generators

As well as the installer Hyperstack includes two generators to create
basic component skeletons.

### Summary:

```
bundle exec rails g hyper:component ComponentName # add a new component
bundle exec rails g hyper:router RouterName # add a new router component
```

both support the following flags:

+ `--no-help` don't add extra comments and method examples
+ `--add-route=...` add a route to this component to the Rails routes file
+ `--base-class=...` change the base class name from the default

### The Component Generator

To add a new component skeleton use the `hyper:component` generator:

```
bundle exec rails g hyper:component ComponentName
```

#### File directories and Name Spacing Components

The above will create a new class definition for `MyComponent` in a file named `my_component.rb` and place it in
the `app/hyperstack/components/` directory.  The component may be name spaced and
will be placed in the appropriate subdirectory.  I.e. `Foo::BarSki` will generate
`app/hyperstack/components/foo/bar_ski.rb`

#### The `--no-help` flag

By default the skeleton will be verbose and contain examples of the most often used
class methods which you can keep or delete as needed.  You can generate a minimal
component with the  `--no-help` flag.

### Router Generator

Typically your top level component will be a *Router* which will take care of dispatching to specific components as the URL changes.  This provides the essence of a *Single Page App* where as the user moves between parts of
the application the URL is updated, the *back* and *forward* buttons work, but the page is **not** reloaded from the server.

A component becomes a router by including the `Hyperstack::Router` module
which provides a number of methods that will be used in the router
component.

To generate a new router skeleton use the `hyper:router` generator:

```
bundle exec rails g hyper:router App
```

> Note that in any Single Page App there will be two routers in play.
On the server the router is responsible dispatching each incoming HTTP request to a
controller.  The controller will deliver back (usually using a view) the contents of the request.
>
> In addition on a Single Page App you will have a router running on the client, which will dispatch to different components depending on the current value of the URL.  The server is only contacted if the current URL leaves the set of URLs that client router knows how to deal with.

#### Adding a Route to the Rails `routes.rb` File

When you generate a new component you can use the `--add-route` option to add the route for you.  For example:

```
bundle exec rails g hyper:router MainApp \
                    --add-route="/(*others)"
```
will add

```ruby
  get '/(*others)', to: 'hyperstack#main_app'
```
to the Rails `routes.rb` file, which will direct all URLS to the `MainApp` component.

For details see **[Routing and Mounting Components.](routing-and-mounting-components.md)**

#### Specifying the Base Class

By default components will inherit from the `HyperComponent` base class.

You can globally override this by changing the value `Hyperstack.component_base_class` in the `hyperstack.rb` initializer.

For example some teams prefer `ApplicationComponent` as their base class name.

You can also override the base class name when generating a component using the `--base-class` option.

This is useful when you have a common library subclass that other classes will inherit from.  For example:

```
bundle exec rails g hyper:component UserBio --base-class=TextArea
```
will generate
```
class UserBio < TextArea
...
end
```
