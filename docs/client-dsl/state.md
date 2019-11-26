# State

In React \(and Hyperstack\) state is mutable. Changes \(mutations\) to state variables cause Components to re-render. Where state is passed into a child Component as a `param`, it will cause a re-rendering of that child Component. Change flows from a parent to a child - change does not flow upward and this is why params are not mutable.

State variables are normal instance variables or objects. When a state variable changes, we use the `mutate` method to get React's attention and cause a re-render. Like normal instance variables, state variables are created when they are first accessed, so there is no explicit declaration.

The syntax of `mutate` is simple - its `mutate` and any other number of parameters and/or a block. Normal evaluation means the parameters are going to be evaluated first, and then `mutate` gets called.

* `mutate @foo = 12, @bar[:zap] = 777` executes the two assignments first, then calls mutate
* or you can say `mutate { @foo = 12; @bar[:zap] = 777 }` which is more explicit, and does the same thing

Here are some examples:

```ruby
class Counter < HyperComponent
  before_mount do
    @count = 0 # optional initialization
  end

  render(DIV) do
    # note how we mutate count
    BUTTON { "+" }.on(:click) { mutate @count += 1) }
    P { @count.to_s }
  end
end
```

```ruby
class LikeButton < HyperComponent
  render(DIV) do
    BUTTON do
      "You #{@liked ? 'like' : 'haven\'t liked'} this. Click to toggle."
    end.on(:click) do
      mutate @liked = !@liked
    end
  end
end
```

### Components are Just State Machines

React thinks of UIs as simple state machines. By thinking of a UI as being in various states and rendering those states, it's easy to keep your UI consistent.

In React, you simply update a component's state, and then the new UI will be rendered on this new state. React takes care of updating the DOM for you in the most efficient way.

### What Components Should Have State?

Most of your components should simply take some params and render based on their value. However, sometimes you need to respond to user input, a server request or the passage of time. For this you use state.

**Try to keep as many of your components as possible stateless.** By doing this you'll isolate the state to its most logical place and minimize redundancy, making it easier to reason about your application.

A common pattern is to create several stateless components that just render data, and have a stateful component above them in the hierarchy that passes its state to its children via `param`s. The stateful component encapsulates all of the interaction logic, while the stateless components take care of rendering data in a declarative way.

State can be held in any object \(not just a Component\). For example:

```ruby
class TestIt
  def self.swap_state
    @@test = !@@test
  end

  def self.result
    @@test ? 'pass' : 'fail'
  end
end

class TestResults < HyperComponent
  render(DIV) do
    P { "Test is #{TestIt.result}" }
    BUTTON { 'Swap' }.on(:click) do
      mutate TestIt::swap_state
    end
  end
end
```

In the example above, the singleton class `TestIt` holds its own internal state which is changed through a `swap_state` class method. The `TestResults` Component has no knowledge of the internal workings of the `TestIt` class.

When the BUTTON is pressed, we call `mutate`, passing the object which is being mutated. The actual mutated value is not important, it is the fact that the _observed_ object \(our `TestIt` class\) is being mutated that will cause a re-render of the _observing_ `TestResults` Component. Think about `mutate` as a way of telling React that the Component needs to be re-rendered as the state has changed.

In the example above, we could also move the _observing_ and _mutating_ behaviour out of the Component completely and manage it in the `TestIt` class - in this case, we would call it a Store. Stores are covered in the Hyper-Store documentation later.

### What Should Go in State?

**State should contain data that a component's instance variables, event handlers, timers, or http requests may change and trigger a UI update.**

When building a stateful component, think about the minimal possible representation of its state, and only store those properties in `state`. Add to your class methods to compute higher level values from your state variables. Avoid adding redundant or computed values as state variables as these values must then be kept in sync whenever state changes.

### What Shouldn't Go in State?

State should contain the minimal amount of data needed to represent your UI's state. As such, it should not contain:

* **Computed data:** Don't worry about precomputing values based on state — it's easier to ensure that your UI is consistent if you do all computation during rendering. For example, if you have an array of list items in state and you want to render the count as a string, simply render `"#{@list_items.length} list items'` in your `render` method rather than storing the count as another state.
* **Data that does not effect rendering:** Changing an instance variable \(or any object\) that does not affect rendering does not need to be mutated \(i.e you do not need to call `mutate`\).

The rule is simple: anytime you are updating a state variable use `mutate` and your UI will be re-rendered appropriately.

### State and user input

Often in a UI you gather input from a user and re-render the Component as they type. For example:

```ruby
class UsingState < HyperComponent

  render(DIV) do
    # the button method returns an HTML element
    # .on(:click) is an event handeler
    # notice how we use the mutate method to get
    # React's attention. This will cause a
    # re-render of the Component
    button.on(:click) { mutate(@show = !@show) }
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
        # using mutate will cause a rerender
        mutate @input_value = evt.target.value
      end
    end
  end

  def output
    # rerender whenever input_value changes
      P { "#{@input_value}" }
  end

  def easter_egg
    H2 {'you found it!'} if @input_value == 'egg'
  end
end
```

### State and HTTP responses

Often your UI will re-render based on the response to a HTTP request to a remote service. Hyperstack does not need to understand the internals of the HTTP response JSON, but does need to _observe_ the object holding that response so we call `mutate` when updating our response object in the block which executes when the HTTP.get promise resolves.

```ruby
class FaaS < HyperComponent
  render(DIV) do
    BUTTON { 'faastruby.io' }.on(:click) do
      faast_ruby
    end

    DIV(class: :block) do
      P { @hello_response['function_response'].to_s }
      P { "executed in #{@hello_response['execution_time']} ms" }
    end if @hello_response
  end

  def faast_ruby
    HTTP.get('https://api.faastruby.io/paulo/hello-world',
      data: {time: true}
    ) do |response|
      # this code executes when the promise resolves
      # notice that we call mutate when updating the state instance variable
      mutate @hello_response = response.json if response.ok?
    end
  end
end
```

### State and updating interval

One common use case is a component wanting to update itself on a time interval. It's easy to use the kernel method `every`, but it's important to cancel your interval when you don't need it anymore to save memory. Hyperstack provides Lifecycle Methods \(covered in the next section\) that let you know when a component is about to be created or destroyed. Let's create a simple mixin that uses these methods to provide a React friendly `every` function that will automatically get cleaned up when your component is destroyed.

```ruby
module ReactInterval

  def self.included(base)
    base.before_mount do
      @intervals = []
    end

    base.before_unmount do
      @intervals.each(&:stop)
    end
  end

  def every(seconds, &block)
    Kernel.every(seconds, &block).tap { |i| @intervals << i }
  end
end

class TickTock < HyperComponent
  include ReactInterval

  before_mount do
    @seconds = 0
  end

  after_mount do
    every(1) { mutate @seconds = @seconds + 1 }
  end

  render(DIV) do
    P { "Hyperstack has been running for #{@seconds} seconds" }
  end
end
```

Notice that TickTock effectively has two `before_mount` methods, one that is called to initialize the `@intervals` array and another to initialize `@seconds`

