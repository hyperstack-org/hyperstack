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

The above will create a new class definition for `ComponentName` in a file named `component_name.rb` and place it in
the `app/hyperstack/components/` directory.  The component may be name spaced and
will be placed in the appropriate subdirectory.  I.e. `Foo::BarSki` will generate
`app/hyperstack/components/foo/bar_ski.rb`

#### The `--no-help` flag

By default the skeleton will be verbose and contain examples of the most often used
class methods which you can keep or delete as needed.  You can generate a minimal
component with the  `--no-help` flag.

### Router Generator

Typically your top level component will be a *Router* which will take care of dispatching to specific components as the URL changes.  This provides the essence of a *Single Page App* where as the user moves between parts of
the application the URL is updated, the back and forward buttons work, but the page is **not** reloaded from the server.

A component becomes a router by including the `Hyperstack::Router` module
which provides a number of methods that will be used in the router
component.

To generate a new router skeleton use the `hyper:router` generator:

```
bundle exec rails g hyper:router App
```

Note that we now have two routers to deal with.  The server still has the `routes.rb` file that maps incoming requests to a Rails controller which
will provide the appropriate response.

On the client the router there maps the current url to a component.

#### Routing to Your Components from Rails

Components can be directly mounted from the Rails `routes.rb` file, using the builtin Hyperstack controller.  

For example a Rails `routes.rb` file containing

```ruby
  get 'some_page/(*others)', to: 'hyperstack#some_component'
```

will route all urls beginning with `some_page` to `SomeComponent`.

When you generate a new component you can use the `--add-route` option to add the route for you.  For example:

```
bundle exec rails g hyper:router SomeComponent \
                    --add-route="some_page/(*others)"
```

would add the route shown above.

Note that typically the Rails route will be going to a Hyperstack Router Component.  That is why we add the wild card to the Rails route so that all urls beginning with `some_page/` will all be handled by `SomeComponent`.

Also note that for the purposes of the example we are using rather dubious names, a more logical setup would be:

```ruby
  get `/(*others)`, to 'hyperstack#app'
```

Which you could generate with
```
bundle exec rails g hyper:router App --add-route="/(*others)"
```

#### Changing the Base Class

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
