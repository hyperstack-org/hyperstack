# Components

# Work in progress - ALPHA (code and docs)

Hyperloop user interfaces are composed of React Components written in Ruby.

Here is the basic structure of a Component:

```ruby
class StrippedBackComponent < Hyperloop::Component
  render(DIV) do
  end
end
```

A Component is just a Ruby class inherited from `Hyperloop::Component`. At a minimum, a Component must implement a `render` macro that returns **just one** HTML element.

Under the covers, Hyperloop uses Opal to compile this Component into JavaScript then hands it to React to mount as a regular JavaScript React Component.

As with React, there are no templates in Hyperloop, your user interface is made up of Components which mix conditional logic and HTML elements to build the user interface. Unlike React, where you code in JSX and JavaScript, Hyperloop lets you keep all your code in Ruby.

Let's add a little functionality to this Component - you can edit this code if you would like to experiment.

```ruby runable
class SimpleComponent < Hyperloop::Component
  render(DIV) do
    BUTTON { 'Push the button' }.on(:click) do
     alert 'You did it!'
    end
  end
end
```

There are a few things to notice in the code above.

+ Every Component must have a `render` macro which must return just one HTML element. The syntax of `render(DIV)` is a shorthand for this which will return one div.
+ HTML built-in elements (DIV, BUTTON, TABLE, etc) are in uppercase, we believe this reads better alongside Components which are in CamelCase and methods in snake_case
+ We added an event handler to the button. You can do this for any HTML element in the same way.

### Rendering Components

Hyperloop's architecture encourages you to write simple Components that perform single tasks and render other Components.

```ruby
class App < Hyperloop::Component
  render(DIV) do
    MainNavigation {}
    PageContents {}
    Footer {}
  end
end
```

This simple approach allows you to build complicated user interfaces yet encapsulate functionality into reusable contained entities.

### Passing parameters

Data is passed downward from a parent Component to its children. There are various techniques for passing data upward and (better still) keeping data in **Stores** independently of Components but we will address that later.

For now, let's experiment with passing parameters:

```ruby runable
class MeeterGreeter < Hyperloop::Component
  render(DIV) do
    SayHelloTo(name: "John")
    SayHelloTo(name: "Sally")
  end
end

class SayHelloTo < Hyperloop::Component
  param :name, type: String

  render(DIV) do
    H4 { "Hello #{params.name}!" }
  end
end
```

You will notice a couple of things in the code above:

+ The syntax for adding components is either `MyComponent()` or `MyComponent {}` but never just `MyComponent`. Sometimes you use both - `BUTTON(class: 'my-class') { "Click Me" }`. Everything in the brackets is passed to the Component as parameters and everything in the curly brace is rendered within the Component.
+ Parameters can be strongly typed `param :name, type: String` and considering this code will be compiled to JavaScript this is a good idea.

### State and Conditional Execution

One of the greatest things about React is that it encourages you to write code in a declarative way with Components that manage their own state (or defer their state to Stores, but we will cover that later). As state changes, React works out how to render the user interface without you having to worry about the DOM - the user interface re-renders itself when it needs to.

The best way to think about this is to imagine your code constantly looping and the program execution changing as the state variables and conditional logic changes. This is pretty much what is going on under the covers, with React being clever about which parts of the UI need to change and be re-rendered.

Lets experiment with an example:

```ruby runable
class StateExample < Hyperloop::Component
  state show_field: false
  state field_value: ""

  render(DIV) do
    show_button
    DIV do
      show_input
      show_text
    end if state.show_field
  end

  def show_button
    BUTTON do
      state.show_field ? "Hide" : "Show"
    end.on(:click) { mutate.show_field !state.show_field }
  end

  def show_input
    BR {}
    INPUT(type: :text).on(:change) do |e|
      mutate.field_value e.target.value
    end
  end

  def show_text
    H1 { "#{state.field_value}" }
  end
end
```

A few things to notice in the code above:

+ We define state using the `state` macro. Notice how we set the initial value.
+ To reference state we use `state.foo` and to mutate (change it) we use mutate `mutate.foo(true)`

### Stylish Components

Conditional logic, HTML elements, state and style all intermingle in a Hyperloop Component.

As an example, this Hyperloop website uses Bootstrap CSS, so we have complete access to the Bootstrap CSS from within our Components:

```ruby runable
class StylishTable < Hyperloop::Component
  render(DIV) do
    TABLE(class: 'table table-bordered') do
      THEAD do
        TR do
          TH { "First Name" }
          TH { "Last Name" }
          TH { "Username" }
          TH { }
        end
      end
      TBODY do
        TR do
          TD { "Mark" }
          TD { "Otto" }
          TD(class: 'text-success') { "@odm" }
          TD { BUTTON(class: 'btn btn-primary btn_sm') { "Edit" } }
        end
      end
    end
  end
end
```

### JavaScript Libraries

JavaScript components are accessed directly from within your Ruby code!

It is important to emphasize that Hyperloop gives you full access to **all JavaScript libraries and components from directly within your Ruby code.** Everything you can do in JavaScript is simple to do in Ruby, this includes passing parameters between Ruby and JavaScript and even passing in Ruby lambdas as JavaScript callbacks.

There are a few ways of accomplishing this, one of which is demonstrated below. Here we wrap a JavaScript library `ReactPlayer` with a Ruby class `Player` so that it is accessible in our Ruby code.

You can also import JavaScript libraries using NPM/Yarn and Webpack/Webpacker and have them available to your Hyperloop Components. We have tutorials which will show you exactly how this works.

```ruby runable
class Player < React::Component::Base
  imports 'ReactPlayer'
end

class LiftOff < Hyperloop::Component

  render(DIV) do
    Player(url:  'https://www.youtube.com/embed/Czrc1JfIBRw',
      playing: false
    )
  end
end
```

That concludes the introduction to Components. To learn more about Components please see the [Tutorials](/tutorials) and also the comprehensive [Docs](/docs/architecture)

In this section, we have shown you how Components work, how you can string them together to build a page, how they pass parameters to their children and even how you can access the complete universe of JavaScript libraries from right within your components.

-------------------------------

Next, we are going to cover [Stores](/start/stores) which are a very clever way of separating our application State from Components so that many Components can share the same state. Using Stores make application design a lot cleaner as you do not need to worry abut passing parameters all over the place.
