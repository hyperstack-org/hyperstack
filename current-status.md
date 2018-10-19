### Current Status:  Working towards 0.1 release.  See Roadmap for details.

`hyperstack-config`, `hyper-store`, and `hyper-component` are now following the public interface conventions.

I.e. to create a component you now do this:

```ruby
class MyComponent
  include Hyperstack::Component
  ...
end
```

The philosophy is that you will probably have a base class defined like this:

```ruby
class HyperComponent 
  include Hyperstack::Component
end
```

Which you can then inherit from.

The bigger change is that the state mechanism has now been greatly simplified, but you can choose when to move
into the future by your choice of which module to include:

```ruby
class HyperComponent
  include Hyperstack::Component
  # to use the current state/store syntax in your components:
  include Hyperstack::Legacy::Store
end

class HyperStore
  # to use the legacy state store syntax in your stores:
  include Hyperstack::Legacy::Store
end
```

To use the new hotness change the includes:

```ruby
class HyperComponent
  include Hyperstack::Component
  # to use the current state/store syntax in your components:
  include Hyperstack::State::Observable
end

class HyperStore
  # to use the legacy state store syntax in your stores:
  include Hyperstack::State::Observable
end
```

In summary you will need to update your hyperloop/hyperstack components and store folders to have `hyper_component.rb` 
and `hyper_store.rb` files.  And then update your components and stores to reference your application defined `HyperComponent`
and `HyperStore` classes.  

### The new world of state:

Its great, its exciting, and its sooo much easier:

Each ruby object has *state*, defined by its instance variables.  Hyperstack does not define *any new state concepts*.  From 
now on you just use instance variables in your components and other objects as you normally would.

The one caveat is that you have to *tell* the system when you are *mutating* state, and when some external entity is
*observing* your state. 

The `Hyperstack::State::Observable` module provides a handful of methods to make this very easy.

Here is an example (compare to the state example on the [Hyperstack.org home page](https://hyperstack.org/))

```ruby
class UsingState < Hyperloop::Component

  # Our component has two instance variables to keep track of what is going on
  #   @show        - if true we will show an input box, otherwise the box is hidden
  #   @input_value - tracks what the user is typing into the input box.
  # We use the mutate method to signal all observers when the state changes.

  render(DIV) do
    # the button method returns an HTML element
    # .on(:click) is an event handeler
    button.on(:click) { mutate @show = !@show }
    DIV do
      input
      output
      easter_egg
    end if @show
  end

  def button
    BUTTON(class: 'ui primary button') do
      @show ? 'Hide' : 'Show'
    end
  end

  def input
    DIV(class: 'ui input fluid block') do
      INPUT(type: :text).on(:change) do |evt|
        # we are updating the value per keypress
        mutate @input_value = evt.target.value
      end
    end
  end

  def output
    # this will re-render whenever input_value changes
	P { "#{@input_value}" }
  end

  def easter_egg
    H2 {'you found it!'} if @input_value == 'egg'
  end
end
```

So to make our instance variables work with components we just need to call `mutate` when the state changes.

Here is a very simple store that is just a global click counter

```ruby
class Click 
  include Hyperstack::State::Observable
  class << self
    def count
      observe @count ||= 0
    end
    def inc
      mutate @count = count + 1
    end
    def count=(x)
      mutate @count = x
    end
    def reset
      mutate @count = 0
    end
  end
end
```

Now any component can access and change the counter by calling `Click.count`, `Click.inc` and `Click.reset` as needed.

The `observe` and `mutate` methods take no params (handy for adding to the end of a method), a single param as shown above,
or a block in which case the entire block will be executed before signaling the rest of the system.

That is all there is to it, but to make things easier `Observable` contains some other helper methods which we can use:

```ruby
class Click
  include Hyperstack::State::Observable
  class << self
    observer(:count) { @count ||= 0 }
    state_writer :count
    mutator(:inc)    { count = count + 1 }
    mutator(:reset)  { count = 0 }
  end
end
```

The `observer` and `mutator` methods create a method wrapped in `observe` or `mutate` block.

In addition there are `state_accessor`, `state_reader` and `state_writer` methods that work just like `attr_accessor` methods
except access is wrapped in the appropriate `mutate` or `observe` method.

The methods can be used either at the class or instance level as needed.

Because stateful components use the same `Observable` module all the above methods are available to help structure your
components nicely.

Notice in the component example we never use `observe` that is because by definition components always `observe` their own
state automatically so you don't need to.

