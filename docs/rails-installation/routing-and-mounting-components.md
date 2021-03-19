## Routing and Mounting Components

Within a Rails Application there are three ways to render or *mount* a
component on a page:

+ Route directly to the component from the rails `routes.rb` file.
+ Render a component directly from a controller.
+ Render a component from within a layout or view file.

### Routing Directly to Components

Components can be directly mounted from the Rails `routes.rb` file, using the builtin Hyperstack controller.  

For example a Rails `routes.rb` file containing

```ruby
  get 'some_page/(*others)', to: 'hyperstack#some_component'
```

will route all urls beginning with `some_page` to `SomeComponent`.

When you generate a new component you can use the `--add-route` option to add the route for you (see the previous section.)

Note that typically the Rails route will be going to a Router Component.  That is why we typically add the wild card to the Rails route so that all urls beginning with `some_page/` will all be handled by `SomeComponent` without having to reload the page.

Also note that for the purposes of the example we used rather dubious names, a more logical setup would be:

```ruby
  get `/(*others)`, to 'hyperstack#app'
```

Which you could generate with
```
bundle exec rails g hyper:router App --add-route="/(*others)"
```

You could also divide your application into several single page apps, for example

```ruby
...
  get 'admin/(*others)', to: 'hyperstack#admin'
  get '/(*others)', to: 'hyperstack#app'
...
```

would route all URLS beginning with admin to the `Admin` component, and everything else
to the main `App` component.  *Note that order of the routes is important as Rails will
dispatch to the first route it matches.*

> If the component is named spaced separate each module with a double underscore (`__`) and
leave the module names CamelCase:
```ruby
  get 'admin/(*others)', to: 'hyperstack#Admin__App'
```

### Rendering a Component from a Controller

To render a component from a controller use the `render_component` helper:

```ruby
  render_component 'Admin', {user_id: params[:id]}, layout: 'admin'
  # would pass the user_id to the Admin component and use the admin layout

  # in general:
  render_component 'The::Component::Name'
                   { ... component params ... },
                   { other render params such as layout }
```

Only the component name is required, but note that if you want to have other
render params, you will have to supply at least an empty hash for the component
params.

### Rendering (or Mounting) a Component from a View

To mount a component directly in a view use the mount_component view helper:

```html
   <%= mount_component 'Clock' %>
```

Like render_component may take params which will be passed to the mounted component.

Mounting a component in an existing view, is a very useful way to integrate Hyperstack
into existing applications.  You mount a component to serve a specific function such as
a dynamic footer or a tweeter feed onto an existing view without having to do a major redesign.
