# Lifecycle Methods

A component may define lifecycle methods for each phase of the components lifecycle:

* `before_mount`
* `render`
* `after_mount`
* `before_new_params`
* `before_update`
* `render` will be called again here
* `after_update`
* `before_unmount`
* `rescues` The `rescues` callback is described **[here...](/error-recovery.md)**

All the Component Lifecycle methods (except `render`) may take a block or the name(s) of instance method(s) to be called.  The `render` method always takes a block.

> The `rescues` callback is described **[here...](/error-recovery.md)**

```ruby
class MyComponent < HyperComponent
  before_mount do
    # initialize stuff here
  end

  render do
    # return just some rendered components
  end

  before_unmount :cleanup  # call the cleanup method before unmounting
  ...
end
```

Except for `render`, multiple lifecycle callbacks may be defined for each lifecycle phase, and will be executed in the order defined, and from most deeply nested subclass outwards.  Note the implication that the callbacks are inherited, which can be useful in creating **[abstract component classes](notes#abstract-and-concrete-components)**.

### Rendering

The lifecycle revolves around rendering the component. As the state or parameters of a component change, its render callback will be executed to generate the new HTML.

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

### Before Mounting \(first render\)

```ruby
before_mount do ...
end
```

Invoked once when the component is first instantiated, immediately before the initial rendering occurs. This is where state variables should be initialized.

This is the only life cycle callback run during `render_to_string` used in server side pre-rendering.

### After Mounting \(first render\)

```ruby
after_mount do ...
end
```

Invoked once, only on the client \(not on the server during prerendering\), immediately after the initial rendering occurs. At this point in the lifecycle, you can access any refs to your children \(e.g., to access the underlying DOM representation\). The `after_mount` callbacks of child components are invoked before that of parent components.

If you want to integrate with other JavaScript frameworks, set timers using the `after` or `every` methods, or send AJAX requests, perform those operations in this callback. Attempting to perform such operations in before\_mount will cause errors during prerendering because none of these operations are available in the server environment.

### Before Receiving New Params

```ruby
before_new_params do |new_params_hash| ...
end
```

Invoked when a component is receiving _new_ params \(React props\). This method is not called for the initial render.

Use this as an opportunity to react to receiving new param values before `render` is called by updating any instance variables. The new\_params block parameter contains a hash of the new values.

```ruby
before_new_params do |next_params|
  @likes_increasing = (next_params[:like_count] > like_count)
end
```

> Note: There is no analogous method `before_receive_state`. An incoming param may cause a state change, but the opposite is not true. If you need to perform operations in response to a state change, use `before_update`.

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

Perform any necessary cleanup in this method, such as cleaning up any DOM elements that were created in the `after_mount` method.  Note that periodic timers and
broadcast receivers are automatically cleaned up when the component is unmounted.

### The `before_render` and `after_render` convenience methods

These call backs occur before and after all renders (first and re-rerenders.)  They provide no added functionality but allow you to keep
your render methods focused on generating components.

### The force\_update! method

`force_update!` is a component instance method that causes the component to re-rerender. This method is seldom \(if ever\) needed.

The `force_update!` instance method causes the component to re-render. Usually this is not necessary as rendering will occur when state variables change, or new params are passed.
