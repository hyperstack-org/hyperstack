
### Param Equality

Params can be arbitrarily

### Params, Immutability and State

Some care must be taken when passing params that are not simple scalars (string, numbers, etc) or JSON like
combinations of arrays and hashes.   When passing more complex objects

Hyperstack differs from React in how it deals with changes in param values

A component will re-render when new param values are received.  If it appears that parameter values have changed,
then the component will not re-render.  For scalars such as strings and numbers and JSON like combinations of arrays
and hashes, the component will be re-rendered if the value of the param changes.  

For more complex objects such as application defined classes, there is generally no way to easily determine that an
object's value has changed.  Hyperstack solves this problem with the `Observable` class, that allows objects to
track which components are depending on their values

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



# Stores

A core concept behind React is that Components contain their own state and pass state down to their children as params. React re-renders the interface based on those state changes. Each Component is discreet and only needs to worry about how to render itself and pass state down to its children.

Sometimes however, at an application level, Components need to be able to share information or state in a way which does not adhere to this strict parent-child relationship.

Some examples of where this can be necessary are:

* Where a child needs to pass a message back to its parent. An example would be if the child component is an item in a list, it might need to inform it's parent that it has been clicked on.
* When Hyperstack models are passed as params, child components might change the values of fields in the model, which might be rendered elsewhere on the page.
* There has to be a place to store non-persisted, global application-level data; like the ID of the currently logged in user or a preference or variable that affects the whole UI.

Taking each of these examples, there are ways to accomplish each:

* Child passing a message to parent: the easiest way is to pass a `Proc` as a param to the child from the parent that the child can `call` to pass a message back to the parent. This model works well when there is a simple upward exchange of information \(a child telling a parent that it has been selected for example\). You can read more about Params of type Proc in the Component section of these docs. If howevere, you find yourself adding overusing this method, or passing messages from child to grandparent then you have reached the limits of this method and a Store would be a better option \(read about Stores in this section.\)
* Models are stores. An instance of a model can be passed between Components, and any Component using the data in a Model to render the UI will re-render when the Model data changes. As an example, if you had a page displaying data from a Model and let's say you have an edit button on that page \(which invokes a Dialog \(Modal\) based Component which receives the model as a param\). As the user edits the Model fields in Dialog, the underlying page will show the changes as they are made as the changes to Model fields will be observed by the parent Components. In this way, Models act very much like Stores.
* Stores are where global, application wide state can exist in singleton classes that all Components can access or as class instances objects which hold data and state. **A Store is a class or an instance of a class which holds state variables which can affect a re-render of any Component observing that data.**

In technical terms, a Store is a class that includes the `include Hyperstack::State::Observable` mixin, which just adds the `mutate` and `observe` primitive methods \(plus helpers built on top of them\).

In most cases, you will want class level instance variables that share data across components. Occasionally you might need multiple instances of a store that you can pass between Components as params \(much like a Model\).

As an example, let's imagine we have a filter field on a Menu Bar in our application. As the user types, we want the user interface to display only the items which match the filter. As many of the Components on the page might depend on the filter, a singleton Store is the perfect answer.

```ruby
# app/hyperstack/stores/item_store.rb
class ItemStore
  include Hyperstack::State::Observable

  class << self
    def filter=(f)
      mutate @filter = f
    end

    def filter
      observe @filter || ''
    end
  end
end
```

In Our application code, we would use the filter like this:

```ruby
# the TextField on the Menu Bar could look like this:
TextField(label: 'Filter', value: ItemStore.filter).on(:change) do |e|
    ItemStore.filter = e.target.value
end

# elsewhere in the code we could use the filter to decide if an item is added to a list
show_item(item) if item.name.include?(ItemStore.filter)
```

## The observe and mutate methods

As with Components, you `mutate` an instance variable to notify React that the Component might need to be re-rendered based on the state change of that object. Stores are the same. When you `mutate` and instance variable in Store, all Components that are observing that variable will be re-rendered.

`observe` records that a Component is observing an instance variable in a Store and might need to be re-rendered if the variable is mutated in the future.

> If you `mutate` an instance variable outside of a Component, you need to `observe` it because, for simplicity, a Component observe their own instance vaibales.

The `observe` and `mutate` methods take:

* a single param as shown above
* a string of params \(`mutate a=1, b=2`\)
* or a block in which case the entire block will be executed before signalling the rest of the system
* no params \(handy for adding to the end of a method\)

## Helper methods

To make things easier the `Hyperstack::State::Observable` mixin contains some useful helper methods:

The `observer` and `mutator` methods create a method wrapped in `observe` or `mutate` block.

* `observer`
* `mutator`

```ruby
mutator(:inc)    { @count = @count + 1 }
mutator(:reset)  { @count = 0 }
```

The `state_accessor`, `state_reader` and `state_writer` methods work just like `attr_accessor` methods except access is wrapped in the appropriate `mutate` or `observe` method. These methods can be used either at the class or instance level as needed.

* `state_reader`
* `state_writer`
* `state_accessor`

Finally there is the `toggle` method which does what it says on the tin.

* `toggle` toggle\(:foo\) === mutate @foo = !@foo

```ruby
class ClickStore
  include Hyperstack::State::Observable

  class << self
    observer(:count) { @count ||= 0 }
    state_writer :count
    mutator(:inc)    { @count = @count + 1 }
    mutator(:reset)  { @count = 0 }
  end
end
```

### Initializing class variables in singleton Store

You can keep the logic around initialization in your Store. Remember that in Ruby your class instance variables can be initialized as the class is defined:

```ruby
class CardStore
  include Hyperstack::State::Observable

  @show_card_status = true
  @show_card_details = false

  class << self
    state_accessor :show_card_status
    state_accessor :show_card_details
  end
end
```
