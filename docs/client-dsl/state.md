When a component is rendered what it displays depends on some combination of three things:

+ the value of the params passed to the component
+ the state of the component
+ the state of some other objects on which a component depends

Whenever one of these three things change the component will need to re-render.  In this section we
discuss how a component's *internal* state is managed within Hyperstack.  Params were covered **[here...](params.md)** and sharing state
between components will be covered **[here...](/hyper-state.md)**

The idea of state is built into Ruby and is represented by the *instance* variables of an object instance.

Components very often have state. For example, is an item being displayed or edited?  What is the current
value of a text box? A checkbox? The time that an alarm should go off?  All these are state and will be
represented as values stored somewhere in instance variables.

Lets look at a simple clock component:

```RUBY
class Clock < HyperComponent
  after_mount do
    every(1.second) do
      mutate @time = Time.now
    end
  end

  render(DIV) { "The time is #{@time}" }
end
```

The after_mount call back sets up a periodic timer that goes off every second and updates the
`@time` instance variable with the current time.  The assignment to `@time` is wrapped in the `mutate` method
which signals the React Engine that the state of `Clock` has been mutated, this in turn will add `Clock` to
the list of components that need to be re-rendered.

### It's that Simple Really

To reiterate: Components (and other Ruby objects) have state, and the state + the params will determine what
is rendered.  When state changes we signal this using the mutate method, and any components depending on the state
will be re-rendered.

### State Mutation Always Drives Rendering

It is always a mutation of state that triggers the UI to begin a render cycle.  That mutation may in turn cause components
to render and send different params to lower level components, but it begins with a state mutation.

### What Causes State To Mutate?

Right!  Good question!  State is mutated by your code's reaction to some external event.  A button click, text being typed,
or the arrival of data from the server.  We will cover these in upcoming sections, but once one an event occurs your
code will probably mutate some state as a result, causing component depending on this state to update.

### Details on the `mutate` Syntax

The main purpose of `mutate` is to signal that state has changed, but it also useful to clarify how your code works.
Therefore `mutate` can be used in a number of flexible ways:

+ It can take any number of expressions:  
```RUBY
mutate @state1 = 'something', @state2 = 'something else'
```
+ or it can take a block:  
```Ruby
mutate do
  ... compute the new state ...
  @state = ...
end
```

In both cases the result returned by `mutate` will be the last expression executed.

### The `mutator` Class Method

This pattern:

```RUBY
class SomeComponent < HyperComponent
  def update_some_state(some_args)
    ... compute new state ...
    mutate ...
  end
  ...
end
```
is common enough that Hyperstack provides two ways to shorten this code.  The first is the
`mutator` class method:
```Ruby
  ...
  mutator :update_some_state do |some_args|
    ...compute new state ...
  end
  ...
```
In other words `mutator` defines a method that is wrapped in a call to `mutate`.  It also has
the advantage of clearly declaring that this method will be mutating the components state.

### The `state_accessor`, `state_reader` and `state_writer` Methods

Often all a mutator method will do is assign a new value to a state.  For this case Hyperstack provides
the `state_accessor`, `state_reader` and `state_writer` methods, that parallel Ruby's `attribute_accessor`,
`attribute_reader` and `attribute_writer` methods:

```Ruby
  state_accessor :some_state
  ...
  some_state = some_state + 1 # or just some_state += some_state
```
In otherwords the `state_accessor` creates methods that allow read/write access to the underlying instance variable
including the call to `mutate`.

Again the advantage is not only less typing but also clarity of code and intention.

### Sharing State

You can also use and share state at the class level and create "stateful" class libraries.  This is described in the **[chapter on HyperState...](/hyper-state.md)**

### The `force_update!` Method

We said above only state mutation can start a rerender.  The `force_update!` method is the exception to this rule, as it will
force a component to rerender just because you said so.  If you have to use `force_update!` you may be doing something
wrong, so use carefully.
