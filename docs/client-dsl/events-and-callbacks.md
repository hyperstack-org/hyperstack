Params pass data downwards from owner to owned-by component.  Data comes back upwards asynchronously
via *callbacks*, which are simply *Procs* passed as params into the owned-by component.

> **[More on Ruby Procs here ...](notes.md#ruby-procs)**

The upwards flow of data via callbacks is triggered by some event such as a mouse click, or input change:

```ruby
class ClickDemo2 < HyperComponent
  render do
    BUTTON { "click" }.on(:click) { |evt| puts "I was clicked"}
  end
end
```

When the `BUTTON` is clicked, the event (evt) is passed to the attached click handler.

The details of the event object will be discussed below.

### Firing Events from Components

You can also define events in your components to communicate back to the owner:

```ruby
class Clicker < HyperComponent
  param title: "click"
  fires :clicked
  before_mount { @clicks = 0 }
  render do
    BUTTON { title }.on(:click) { clicked!(@clicks += 1) }
  end
end

class ClickDemo3 < HyperComponent
  render(DIV) do
    DIV { "I have been clicked #{pluralize(@clicks, 'times')}" } if @clicks
    Clicker().on(:clicked) { |clicks| mutate @clicks = clicks }
  end
end
```

Each time the `Clicker's` button is clicked it *fires* the clicked event, indicated
by the event name followed by a bang (!).

The `clicked` event is received by `ClickDemo3`, and it updates its state.  As you
can see events can send arbitrary data back out.

> Notice also that Clicker does not call mutate.  It could, but since the change in
`@clicks` is not used anywhere to control its display there is no need for Clicker  
to mutate.

### Relationship between Events and Params

Notice how events (and callbacks in general as we will see) move data upwards, while
params move data downwards.  We can emphasize this by updating our example:

```ruby
class ClickDemo4 < HyperComponent
  def title
    @clicks ? "Click me again!" : "Let's start clicking!"
  end

  render(DIV) do
    DIV { "I have been clicked #{pluralize(@clicks, 'times')}" } if @clicks
    Clicker(title: title).on(:clicked) { |clicks| mutate @clicks = clicks }
  end
end
```

When `ClickDemo4` is first rendered, the `title` method will return "Let's start clicking!", and
will be passed to `Clicker`.

The user will (hopefully so we can get on with this chapter) click the button, which will
fire the event. The handler in `ClickDemo4` will mutate its state, causing title to change
to "Click me again!".  The new value of the title param will be passed to `Clicker`, and `Clicker`
will re-render with the new title.

**Events (and callbacks) push data up, params move data down.**

### Callbacks and Proc Params

Under the hood Events are simply params of type `Proc`, with the `on` and `fires` method
using some naming conventions to clean things up:

```ruby
class IntemittentButton < HyperComponent
  param :frequency
  param :pulse, type: Proc
  before_mount { @clicks = 0 }
  render do
    BUTTON(
      on_click: lambda {} do
        @clicks += 1
        pulse(@clicks) if (@clicks % frequency).zero?
      end
    ) { 'click me' }
  end
end

class ClickDemo5 < HyperComponent
  render do
    IntermittentButton(
      frequency: 5,
      pulse: -> (total_clicks) { alert "you are clicking a lot" }
    )
  end
end
```

There is really no reason not to use the `fires` method to declare Proc params, and
no reason not use the `on` method to attach handlers.  Both will keep your code clean and tidy.

### Naming Conventions

The notation `on(:click)` is short for passing a proc to a param named `on_click`.  In general `on(:xxx)` will pass the
given block as the `on_xxx` parameter in a Hyperstack component and `onXxx` in a JS component.  

All the built-in events and many React libraries follow the `on_xxx` (or `onXxx` in JS) convention. However even if a library does not use
this convention you can still attach the handler using `on('<name-of-param>')`.  Whatever string is inside the `<..>` brackets will
be used as the param name.

Likewise the `fires` method is shorthand for creating a `Proc` param following the `on_xxx` naming convention:

`fires :foo` is short for  
`param :on_foo, type: Proc, alias: :foo!`

### The `Event` Object

UI events like `click` send an object of class `Event` to the handler.  Some of the data you can get from `Event` objects are:

+ `target` : the DOM object that was the target of the UI interaction
+ `target.value` : the value of the DOM object
+ `key_code` : the key pressed (for key_down and key_up events)

> **[Refer to the Predefined Events section for complete details...](predefined-events.md)**

### Other Sources of Events

Besides the UI there are several other sources of events:

+ Timers
+ HTTP Requests
+ Hyperstack Operations
+ Websockets
+ Web Workers

The way you receive events from these sources depends on the event.  Typically though the method will either take a block, or callback proc, or in many cases will return a Promise.
Regardless, the event handler will do one of three things:  mutate some state within the component, fire an event to a higher level component, or update some shared store.

> For details on updating shared stores, which is often the best answer **[see the chapter on HyperState...](../hyper-state/README.md)**

You have seen the `every` method used to create events throughout this chapter, here is an example with an HTTP post (which returns a promise.)

```ruby
class SaveButton < HyperComponent
  fires :saved
  fires :failed
  render do
    BUTTON { "Save" }
    .on(:click) do
      # Posting to some non-hyperstack endpoint for example
      # Data is our class holding some data
      Hyperstack::HTTP.post(
        END_POINT, payload: Data.to_payload
      ).then do |response|
        saved!(response.json)
      end.fail do |response|
        failed!(response.json)
      end
    end
  end
end
```           
