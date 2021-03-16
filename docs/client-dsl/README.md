# Client DSL

## Hyperstack Component Classes and DSL

Your Hyperstack Application is built from a series of *Components* which are Ruby Classes that display portions of the UI. Hyperstack Components are implemented using [React](https://reactjs.org/), and can interoperate with existing React components and libraries.  Here is a simple example that displays a ticking clock:

```ruby
# Components inherit from the HyperComponent base class
# which supplies the DSL to translate from Ruby into React
# function calls
class Clock < HyperComponent
  # before_mount is an example of a life cycle method.
  before_mount do
    # before the component is first rendered (mounted)
    # we setup a periodic timer that will update the  
    # current_time instance variable every second.
    every(1.second) { mutate @current_time = Time.now }
  end
  # every component has a render block which describes what will be
  # drawn on the UI
  render do
    # Components can render other components or primitive HTML or SVG
    # tags.  Components also use their state to determine what to render,
    # in this case the @current_time instance variable
    DIV { @current_time.strftime("%m/%d/%Y %I:%M:%S")
  end
end
```

This documentation will cover the following core concepts, many of which
are touched on in the above simple example:

+ [HTML & CSS DSL](html-css.md) which provides Ruby implementations of all of the HTML and CSS elements
+ [The Component DSL](components.md) is a Ruby DSL which wraps ReactJS Components
+ [Lifecycle Methods](lifecycle-methods.md) are methods which are invoked before, during and after rendering
+ [State](state.md) - components rerender as needed when state changes.
+ [Event Handlers](event-handlers.md) allow any HTML element or Component to respond to an event, plus custom events can be described.
+ [JavaScript Components](javascript-components.md) access to the full universe of JS libraries in your Ruby code
+ [Client-side Routing](hyper-router.md) a Ruby DSL which wraps ReactRouter
+ [Stores](hyper-store.md) for application level state and Component communication
+ [Elements and Rendering](elements-and-rendering.md) details of the underlying mechanisms.
+ [Further Reading](further-reading.md) on React and Opal
