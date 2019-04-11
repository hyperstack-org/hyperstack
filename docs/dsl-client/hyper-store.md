# Stores

**DRAFT DOCS**

A core concept behind React is that Components contain their own state and pass state down to their children as params. React re-renders the interface based on those state changes. Each Component is discreet and only needs to worry about how to render itself and pass state down to its children.

Sometimes though, at an application level, Components need to be able to share state in a way which breaks this parent-child relationship.

Some examples of where this can be necessary are:

+ Where a child needs to pass a state change back to its parent (for example if the child component is an item in a list, and clicking on it needs to alter the page the parent is rendering).

+ When Hyperstack models are passed as params, child components might need to mutate the fields in the model, which will be rendered elsewhere on the page, causing re-rendering

+ Global application-level settings; like the ID of the currently logged in user or a preference or variable that affects the whole UI

Taking each of these examples, there are ways to accomplish each:

+ Child passing a message to parent: the easiest way is to pass a Proc as a param to the child from the parent that the child can `call` to pass a message back to the parent. This model works well with a list of items which need to inform their container if they have been selected (causing a re-render of the container). You can read more about Params of type Proc in the Component section of these docs.

+ Models are stores. An instance of a model can be passed between Components, and any Component using the data in a Model to render the UI will re-render when the Model data changes. As an example, if you had a page displaying data from a Model and let's say you have an edit button on that page (which invokes a Dialog (Modal) based Component which receives the model as a param). As the user edits the Model fields in Dialog, the underlying page will show the changes as they are made as the changes to Model fields will be observed by the parent Components.

+ Global, application wide state can exist in singleton classes that all Components can access. This is the core idea behind a store. A Store is a class or an instance of a Class which holds state variables which can affect a re-render of any Component observing that data.

In technical terms, a Store is a class that includes the `include Hyperstack::State::Observable` mixin, which just adds the `mutate` and `observe` primitive methods (plus helpers built on top of them).

In most cases, you will want class level instance variables that share data across components. Occasionally you might need multiple instances of a store that you can pass between Components as params (much like a Model).

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
# the text filed on the Menu Bar could look like this:
TextField(label: 'Filter', value: ItemStore.filter).on(:change) do |e|
    ItemStore.filter = e.target.value
end

# elsewhere we could use the filter to decide if an item is added to a list
show_item(item) if item.name.to_s.upcase.include?(ItemStore.filter.upcase)
```

## The observe and mutate methods

As with Components, you `mutate` an instance variable to notify React that the Component might need to be re-rendered based on the state change of that object. Stores are the same. When you `mutate` and instance variable in Store, all Components that are observing that variable will be re-rendered.

`observe` records that the current react Component being rendered has observed this object, and will need to be re-rendered if the object is mutated in the future.

If you `mutate` an instance variable outside of a Component, you need to `observe` it because, for simplicity, a Component observes itself.

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

The `observe` and `mutate` methods take no params (handy for adding to the end of a method), a single param as shown above, or a block in which case the entire block will be executed before signalling the rest of the system.

## Helper methods

To make things easier the `Hyperstack::State::Observable` mixin contains some additional helper methods:

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

In addition there are `state_accessor`, `state_reader` and `state_writer` methods that work just like `attr_accessor` methods except access is wrapped in the appropriate `mutate` or `observe` method.

The methods can be used either at the class or instance level as needed.

Because stateful components use the same `Observable` module all the above methods are available to help structure your
Components nicely. Notice in the component example we never use `observe` that is because by definition Components always `observe` their own state automatically so you don't need to.


--------------------------------------------------------------------
Other text....

```ruby
class Clock
  include Hyperstack::State::Observable
  class << self
    def current_time
      @time ||= Time.now
      @timer ||= every(60.seconds) { mutate @time = Time.now }
      observe @time
    end
  end
end
```

a component then does a Clock.current_time and gets the current time, and is now observing the Clock.
a minute later the clock will wake up, and mutate @time, which will cause every component that has observed the clock to be rerendered.


```ruby
class ClickCounter
  include Hyperstack::State::Observable
  class << self
    def click!
      mutate @click = (@click || 0) + 1
    end
    def clicks
      observe @click
    end
  end
end
```

there are helpers to make this read nicer:

```ruby
 class ClickCounter
  include Hyperstack::State::Observable
  class << self
    mutator :click! { @click = (@click || 0) + 1 }  # just calls mutate for you, but also makes it clear to the reader
    state_reader :clicks # just like attr_reader but does an observe, also you have state_writer, and state_accessor
  end
end
```

Mitch VanDuyn @catmando Mar 28 17:51
also there is the handy toggle method: toggle(:foo) === mutate @foo = !@foo
and that is about it. everything is based on the observe and mutate method so once you understand those the rest are easy.
and by the way for handiness observe and mutate's signature is like this

`def mutate(*args, &block)`
so you can say mutate @foo = 12, @bar = 77
throws all the args away except the last which it returns.
or you can say mutate do ... end if you need to evaluate a bunch of complex stuff and return the last value.
it all does the same thing, so its just sugar so the code looks nice.

Mitch VanDuyn @catmando Mar 28 17:56
Note you observe and mutate the object not any particular instance variable.
A final niceity (you will see this in the stock ticker) ... the system will take care of cleaning up things like timers when an object is no longer used. Not sure if you even want to document that.

Mitch VanDuyn @catmando Mar 28 23:28
In above examples instance variable would be better named @clicks
The state_reader :clicks


Or a better example:

```ruby
class ClickCounter
 include Hyperstack::State::Observable
 class << self
   mutator :click! { @click = (@click || 0) + 1 }  # just calls mutate for you, but also makes it clear to the reader
   state_reader :click # just like attr_reader but does an observe, also you have state_writer, and state_accessor
 end
```
