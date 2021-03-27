The Hyperstack Component DSL is a set of class and instance methods that are used to describe React components and render the user-interface.

The following sections give a brief orientation to the structure of a component and the methods that are used to define and control its behavior.

## Defining a Component

Hyperstack Components are Ruby classes that inherit from the `HyperComponent` base class:

```ruby
class MyComponent < HyperComponent
  ...
end
```
> **[More on the HyperComponent base class](notes.md#the-hypercomponent-base-class)**

## The `render` Callback

At a minimum every *concrete* component class must define a `render` block which generates one or more child elements. Those children may in turn have an arbitrarily deep structure.  **[More on concrete and abstract components...](notes.md#abstract-and-concrete-components)**

```ruby
class Component < HyperComponent
  render do
    DIV { } # render an empty div
  end
end
```  
> The code between `do` and `end` and { .. } are called blocks.  **[More here...](notes.md#blocks-in-ruby)**

To save a little typing you can also specify the top level element to be rendered:

```ruby
class Component < HyperComponent
  render(DIV, class: 'my-special-class') do
    # everything will be rendered in a div
  end
end
```

To create a component instance, you reference its class name as a method call from another component. This creates a new instance, passes any parameters and proceeds with the component lifecycle.

> **[The actual type created is an Element read on for details...](notes.md#component-instances)**

```ruby
class FirstComponent < HyperComponent
  render do
    NextComponent() # ruby syntax requires either () or {} following the class name
  end
end
```

> While a component is defined as a class, and a rendered component is an instance of that class, we do not in general use the `new` method, or need to modify the components `initialize` method.

### Invoking Components

> Note: when invoking a component **you must have** a \(possibly empty\) parameter list or \(possibly empty\) block.
> ```ruby
MyCustomComponent()  # ok
MyCustomComponent {} # ok
MyCustomComponent    # <--- breaks
> ```

## Component Params

A component can receive params to customize its look and behavior:

```Ruby
class SayHello < HyperComponent
  param :to
  render(DIV, class: :hello) do
    "Hello #{to}!"
  end
end

...

  SayHello(to: "Joe")
```

Components can receive new params, causing the component to update.  **[More on Params ...](params.md)**.

## Component State

Components also have *state*, which is stored in instance variables.  You signal a state change using the `mutate` method. Component state is a fundamental concept covered **[here](state.md)**.


## Life Cycle Callbacks

A component may be updated during its life time due to either changes in state or receiving new params.  You can hook into the components life cycle using the
the life cycle methods.  Two of the most common lifecycle methods are `before_mount` and `after_mount` that are called before a component first renders, and
just after a component first renders respectively.

```RUBY
class Clock < HyperComponent
  param format: "%m/%d/%Y %I:%M:%S"
  after_mount do
    every(1.second) { mutate @current_time = Time.now }
  end
  render do
    DIV { @current_time.strftime(format) }
  end
end
```

The complete list of life cycle methods and their syntax is discussed in detail in the **[Lifecycle Methods](lifecycle-methods.md)** section.

## Events, Event Handlers, and Component Callbacks

Events such as mouse clicks trigger callbacks, which can be attached using the `on` method:

```ruby
class ClickCounter < HyperComponent
  before_mount { @clicks = 0 }
  def adverb
    @clicks.zero? ? 'please' : 'again'
  end
  render(DIV) do
    BUTTON { "click me #{adverb}" }
    .on(:click) { mutate @clicks += 1 } # attach a callback
    DIV { "I've been clicked #{pluralize(@clicks, 'time')}" } if @clicks > 0
  end
end
```

This example also shows how events and state mutations work together to change the look of the display.  It also demonstrates that because a HyperComponent
is just a Ruby class you can define helper methods, use conditional logic, and call on predefined methods like `pluralize`.

In addition components can fire custom events, and make callbacks to the upper level components.  **[More details ...](events-and-callbacks.md)**

## Application Structure

Your Application is built out of many smaller components using the above features to control the components behavior and communicate between components. To conclude this section let's create a simple Avatar component which shows a profile picture and username using the Facebook Graph API.

```ruby
class Avatar < HyperComponent
  param :user_name

  render(DIV) do
    # for each param a method with the same name is defined
    ProfilePic(user_name: user_name)
    ProfileLink(user_name: user_name)
  end
end

class ProfilePic < HyperComponent
  param :user_name

  # note that in Ruby blocks can use do...end or { ... }
  render { IMG(src: "https://graph.facebook.com/#{user_name}/picture") }
end

class ProfileLink < HyperComponent
  param :user_name
  render do
    A(href: "https://www.facebook.com/#{user_name}") do
      user_name
    end
  end
end
```
