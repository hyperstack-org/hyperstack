# HyperComponent DSL - Basics

The Hyperstack Component DSL is a set of class and instance methods that are used to describe React components and render the user-interface.

The DSL has the following major areas:

* The `HyperComponent` class
* HTML DSL elements
* Component Lifecycle Methods \(`before_mount`, `after_mount`, `after_update`\)
* The `param` and `render` methods
* Event handlers
* Miscellaneous methods

## Defining a Component

Hyperstack Components are Ruby classes that inherit from the `HyperComponent` base class:

```ruby
class MyComponent < HyperComponent
  ...
end
```
> **[More on the HyperComponent base class](notes.html#the-hypercomponent-base-class)**

## The `render` Callback

At a minimum every *concrete* component class must define a `render` block which generates one or more child elements. Those children may in turn have an arbitrarily deep structure.  **[More on concrete and abstract components](notes.html#abstract-and-concrete-components)**

```ruby
class Component < HyperComponent
  render do
    DIV { } # render an empty div
  end
end
```  
> The code between the `do` and `end` is called a block.  **[More here...](notes.html#blocks-in-ruby)**

To save a little typing you can also specify the top level element to be rendered:

```ruby
class Component < HyperComponent
  render(DIV, class: 'my-special-class') do
    # everything will be rendered in a div
  end
end
```

To render a component, you reference its class name as a method call from another component. This creates a new instance, passes any parameters and proceeds with the component lifecycle.

```ruby
class FirstComponent < HyperComponent
  render do
    NextComponent() # ruby syntax requires either () or {} following the class name
  end
end
```

Note that you should never redefine the `new` or `initialize` methods, or call them directly. The equivalent of `initialize` is the `before_mount` method.  

> The one exception to using `new` is within a spec to create a "headless" component in order to access its internal state and methods.

### Invoking Components

> Note: when invoking a component **you must have** a \(possibly empty\) parameter list or \(possibly empty\) block.
> ```ruby
MyCustomComponent()  # ok
MyCustomComponent {} # ok
MyCustomComponent    # <--- breaks
> ```

## Multiple Components

So far, we've looked at how to write a single component to display data. Next let's examine how components are combined to build an application.

By building modular components that reuse other components with well-defined interfaces you can _separate the different concerns_ of your app. By building a custom component library for your application, you are expressing your UI in a way that best fits your domain.

### Composition Example

Let's create a simple Avatar component which shows a profile picture and username using the Facebook Graph API.

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
