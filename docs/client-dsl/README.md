Your Hyperstack Application is built from a series of *Components* which are Ruby Classes that display portions of the UI. Hyperstack Components are implemented using [React](https://reactjs.org/), and can interoperate with existing React components and libraries.  Here is a simple example that displays a ticking clock:

```ruby
# Components inherit from the HyperComponent base class
# which supplies the DSL to translate from Ruby into React
# function calls
class Clock < HyperComponent
  # Components can be parameterized.
  # in this case you can override the default
  # with a different format
  param format: "%m/%d/%Y %I:%M:%S"
  # After_mount is an example of a life cycle method.
  after_mount do
    # Before the component is first rendered (mounted)
    # we setup a periodic timer that will update the  
    # current_time instance variable every second.
    # The mutate method signals a change in state
    every(1.second) { mutate @current_time = Time.now }
  end
  # every component has a render block which describes what will be
  # drawn on the UI
  render do
    # Components can render other components or primitive HTML or SVG
    # tags.  Components also use their state to determine what to render,
    # in this case the @current_time instance variable
    DIV { @current_time.strftime(format) }
  end
end
```

The following chapters cover these aspects and more in detail.
