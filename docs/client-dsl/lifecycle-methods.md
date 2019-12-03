# Lifecycle Methods

A component may define lifecycle methods for each phase of the components lifecycle:

* `before_mount`
* `render`
* `after_mount`
* `before_receive_props`
* `before_update`
* `after_update`
* `before_unmount`

> Note: At a minimum, one `render` method must be defined and must return just one HTML element.

All the Component Lifecycle methods may take a block or the name of an instance method to be called.

```ruby
class MyComponent < HyperComponent
  before_mount do
    # initialize stuff here
  end

  render do
    # return just one HTML element
  end

  before_unmount :cleanup  # call the cleanup method before unmounting
  ...
end
```

Except for the render method, multiple lifecycle methods may be defined for each lifecycle phase, and will be executed in the order defined, and from most deeply nested subclass outwards.

## Lifecycle Methods

A component class may define lifecycle methods for specific points in a component's lifecycle.

### Rendering

The lifecycle revolves around rendering the component. As the state or parameters of a component changes, its render method will be called to generate the new HTML.

```ruby
render do ....
end
```

The render method may optionally take the container component and params:

```ruby
render(DIV, class: 'my-class') do
  ...
end
```

which would be equivalent to:

```ruby
render do
  DIV(class: 'my-class') do
    ...
  end
end
```

The purpose of the render method is syntactic. Many components consist of a static outer container with possibly some parameters, and most component's render method by necessity will be longer than the normal _10 line_ ruby style guideline. The render method solves both these problems by allowing the outer container to be specified as part of the method parameter \(which reads very nicely\) and because the render code is now specified as a block you avoid the 10 line limitation, while encouraging the rest of your methods to adhere to normal ruby style guides

### Before Mounting \(first render\)

```ruby
before_mount do ...
end
```

Invoked once when the component is first instantiated, immediately before the initial rendering occurs. This is where state variables should be initialized.

This is the only life cycle method that is called during `render_to_string` used in server side pre-rendering.

### After Mounting \(first render\)

```ruby
after_mount do ...
end
```

Invoked once, only on the client \(not on the server\), immediately after the initial rendering occurs. At this point in the lifecycle, you can access any refs to your children \(e.g., to access the underlying DOM representation\). The `after_mount` methods of children components are invoked before that of parent components.

If you want to integrate with other JavaScript frameworks, set timers using the `after` or `every` methods, or send AJAX requests, perform those operations in this method. Attempting to perform such operations in before\_mount will cause errors during prerendering because none of these operations are available in the server environment.

### Before Receiving New Params

```ruby
before_receive_props do |new_params_hash| ...
end
```

Invoked when a component is receiving _new_ params \(React.js props\). This method is not called for the initial render.

Use this as an opportunity to react to a prop transition before `render` is called by updating any instance or state variables. The new\_props block parameter contains a hash of the new values.

```ruby
before_receive_props do |next_props|
  mutate @likes_increasing = (next_props[:like_count] > @LikeCount)
end
```

> Note: There is no analogous method `before_receive_state`. An incoming param may cause a state change, but the opposite is not true. If you need to perform operations in response to a state change, use `before_update`.

TODO: The above needs to be checked and a better example provided. PR very welcome.

### Controlling Updates

Normally Hyperstack will only update a component if some state variable or param has changed. To override this behavior you can redefine the `should_component_update?` instance method. For example, assume that we have a state called `funky` that for whatever reason, we cannot update using the normal `state.funky!` update method. So what we can do is override `should_component_update?` call `super`, and then double check if the `funky` has changed by doing an explicit comparison.

```ruby
class RerenderMore < HyperComponent
  def should_component_update?(new_params_hash, new_state_hash)
    super || new_state_hash[:funky] != state.funky
  end
end
```

Why would this happen? Most likely there is integration between new Hyperstack Components and other data structures being maintained outside of Hyperstack, and so we have to do some explicit comparisons to detect the state change.

Note that `should_component_update?` is not called for the initial render or when `force_update!` is used.

> Note to react.js readers. Essentially Hyperstack assumes components are "well behaved" in the sense that all state changes will be explicitly declared using the state update \("!"\) method when changing state. This gives similar behavior to a "pure" component without the possible performance penalties. To achieve the standard react.js behavior add this line to your class `def should_component_update?; true; end`

### Before Updating \(re-rendering\)

```ruby
before_update do ...
end
```

Invoked immediately before rendering when new params or state are being received.

### After Updating \(re-rendering\)

```ruby
after_update do ...
end
```

Invoked immediately after the component's updates are flushed to the DOM. This method is not called for the initial render.

Use this as an opportunity to operate on the DOM when the component has been updated.

### Unmounting

```ruby
before_unmount do ...
end
```

Invoked immediately before a component is unmounted from the DOM.

Perform any necessary cleanup in this method, such as invalidating timers or cleaning up any DOM elements that were created in the `after_mount` method.

### The force\_update! method

`force_update!` is a component instance method that causes the component to re-rerender. This method is seldom \(if ever\) needed.

The `force_update!` instance method causes the component to re-render. Usually this is not necessary as rendering will occur when state variables change, or new params are passed.

