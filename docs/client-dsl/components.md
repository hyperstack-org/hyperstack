# Hyperstack Component DSL

The Hyperstack Component DSL is a set of class and instance methods that are used to describe React components and render the user-interface.

The DSL has the following major areas:

* The `HyperComponent` class
* HTML DSL elements
* Component Lifecycle Methods \(`before_mount`, `after_mount`, `after_update`\)
* The `param` and `render` methods
* Event handlers
* Miscellaneous methods

## HyperComponent

By convention your Hyperstack Components will inherit from the `HyperComponent` class, which typically would look like this:

```ruby
class HyperComponent
  # All component classes must include Hyperstack::Component
  include Hyperstack::Component
  # The Observable module adds state handling
  include Hyperstack::State::Observable
  # The following turns on the new style param accessor
  # i.e. param :foo is accessed by the foo method
  param_accessor_style :accessors
end

# and is used like this:

class AnotherComponent < HyperComponent
  ...
end
```

Having an Application wide HyperComponent class allows you to modify component behavior on an application basis, similar to the way Rails uses `ApplicationRecord` and `ApplicationController` classes.

## The `render` Callback

At a minimum every component class must define a `render` block which returns one or more child elements. Those children may in turn have an arbitrarily deep structure.

```ruby
class Component < HyperComponent
  render do
    DIV { } # render an empty div
  end
end
```

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

So far, we've looked at how to write a single component to display data. Next let's examine one of React's finest features: composability.

### Motivation: Separation of Concerns

By building modular components that reuse other components with well-defined interfaces, you get much of the same benefits that you get by using functions or classes. Specifically you can _separate the different concerns_ of your app however you please simply by building new components. By building a custom component library for your application, you are expressing your UI in a way that best fits your domain.

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

  render do
    IMG(src: "https://graph.facebook.com/#{user_name}/picture")
  end
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

### Ownership

In the above example, instances of `Avatar` _own_ instances of `ProfilePic` and `ProfileLink`. In React, **an owner is the component that sets the `params` of other components**. More formally, if a component `X` is created in component `Y`'s `render` method, it is said that `X` is _owned by_ `Y`. As discussed earlier, a component cannot mutate its `params` — they are always consistent with what its owner sets them to. This fundamental invariant leads to UIs that are guaranteed to be consistent.

It's important to draw a distinction between the owner-ownee relationship and the parent-child relationship. The owner-ownee relationship is specific to React, while the parent-child relationship is simply the one you know and love from the DOM. In the example above, `Avatar` owns the `div`, `ProfilePic` and `ProfileLink` instances, and `div` is the **parent** \(but not owner\) of the `ProfilePic` and `ProfileLink` instances.

### Children

When you create a React component instance, you can include additional React components or JavaScript expressions between the opening and closing tags like this:

```ruby
Parent { Child() }
```

`Parent` can iterate over its children by accessing its `children` method.

### Child Reconciliation

**Reconciliation is the process by which React updates the DOM with each new render pass.** In general, children are reconciled according to the order in which they are rendered. For example, suppose we have the following render method displaying a list of items. On each pass the items will be completely re-rendered:

```ruby
param :items
render do
  items.each do |item|
    P do
      item[:text]
    end
  end
end
```

What if the first time items was `[{text: "foo"}, {text: "bar"}]`, and the second time items was `[{text: "bar"}]`? Intuitively, the paragraph `<p>foo</p>` was removed. Instead, React will reconcile the DOM by changing the text content of the first child and destroying the last child. React reconciles according to the _order_ of the children.

### Dynamic Children

The situation gets more complicated when the children are shuffled around \(as in search results\) or if new components are added onto the front of the list \(as in streams\). In these cases where the identity and state of each child must be maintained across render passes, you can uniquely identify each child by assigning it a `key`:

```ruby
  param :results, type: [Hash] # each result is a hash of the form {id: ..., text: ....}
  render do
    OL do
      results.each do |result|
        LI(key: result[:id]) { result[:text] }
      end
    end
  end
```

When React reconciles the keyed children, it will ensure that any child with `key` will be reordered \(instead of clobbered\) or destroyed \(instead of reused\).

The `key` should _always_ be supplied directly to the components in the array, not to the container HTML child of each component in the array:

```ruby
# WRONG!
class ListItemWrapper < HyperComponent
  param :data
  render do
    LI(key: data[:id]) { data[:text] }
  end
end  

class MyComponent < HyperComponent
  param :results
  render do
    UL do
      result.each do |result|
        ListItemWrapper data: result
      end
    end
  end
end
```

```ruby
# CORRECT
class ListItemWrapper < HyperComponent
  param :data
  render do
    LI { data[:text] }
  end
end

class MyComponent < HyperComponent
  param :results
  render do
    UL do
      results.each do |result|
        ListItemWrapper key: result[:id], data: result
      end
    end
  end
end
```

> The `to_key` method:  Any ruby object can be a key.  Under the hood the HyperComponent DSL will call the object's `to_key` method which will respond with a unique value representing the object.  For example if you pass an ActiveRecord model instance as a key, the result will be the database id of the model.  

### The children and render methods

Along with the params hash components may be passed a block which is used to build the components children.

The instance method `children` returns an enumerable that is used to access the *unrendered* children of a component.  The children can then be rendered
using the `render` method which will merge any additional parameters and
render the child.

```ruby
class Indenter < HyperComponent
  render(DIV) do
    IndentEachLine(by: 10) do # see IndentEachLine below
      DIV {"Line 1"}
      DIV {"Line 2"}
      DIV {"Line 3"}
    end
  end
end

class IndentEachLine < HyperComponent
  param by: 20, type: Integer

  render(DIV) do
    children.each_with_index do |child, i|
      child.render(style: {"margin-left" => by*i})
    end
  end
end
```

### Rendering Multiple Values and the FRAGMENT component

A render block may generate multiple values.  React assumes when a Component generates multiple items, the item order and quantity may
change over time and so will give a warning unless each element has a key:

```ruby
class ListItems < HyperComponent
  render do
    LI(key: 1) { 'item 1' }
    LI(key: 2) { 'item 2' }
    LI(key: 3) { 'item 3' }
  end
end

# somewhere else:
   UL do
     ListItems()
   end
```

If you are sure that the order and number of elements will not change over time you may wrap the items in the FRAGMENT pseudo component:

```ruby
class ListItems < HyperComponent
  render(FRAGMENT) do
    LI { 'item 1' }
    LI { 'item 2' }
    LI { 'item 3' }
  end
end
```

The only param that FRAGMENT may take is a key, which is useful if there will be multiple fragments being merged at some higher level.


### Data Flow

In React, data flows from owner to owned component through the params as discussed above. This is effectively one-way data binding: owners bind their owned component's param to some value the owner has computed based on its `params` or `state`. Since this process happens recursively, data changes are automatically reflected everywhere they are used.

### Stores

Managing state between components is best done using Stores as many Components can access one store. This saves passing data between Components. Please see the [Store documentation](https://docs.hyperstack.org/client-dsl/hyper-store) for details.

### Reusable Components

When designing interfaces, break down the common design elements \(buttons, form fields, layout components, etc.\) into reusable components with well-defined interfaces. That way, the next time you need to build some UI, you can write much less code. This means faster development time, fewer bugs, and fewer bytes down the wire.

## Params

The `param` method gives _read-only_ access to each of the scalar params passed to the Component. Params are accessed as instance methods on the Component.

Within a React Component the `param` method is used to define the parameter signature of the component. You can think of params as the values that would normally be sent to the instance's `initialize` method, but with the difference that a React Component gets new parameters when it is re-rendered.

Note that the default value can be supplied either as the hash value of the symbol, or explicitly using the `:default_value` key.

Examples:

```ruby
param :foo # declares that we must be provided with a parameter foo when the component is instantiated or re-rerendered.
param :foo, alias: :something       # the alias name will be used for the param (instead of Foo)
param :foo => "some default"        # declares that foo is optional, and if not present the value "some default" will be used.
param foo: "some default"           # same as above using ruby 1.9 JSON style syntax
param :foo, default: "some default" # same as above but uses explicit default key
param :foo, type: String            # foo is required and must be of type String
param :foo, type: [String]          # foo is required and must be an array of Strings
param foo: [], type: [String]       # foo must be an array of strings, and has a default value of the empty array.
```

#### Accessing param values

Params are accessible in the Component class as instance methods.

For example:

```ruby
class Hello < HyperComponent
  # an immutable parameter, with a default of type String
  param visitor: "World", type: String

  render do
    "Hello #{visitor}"
  end
end
```

### Immutable params

A core design concept taken from React is that data flows down to child Components via params and params \(called props in React\) are immutable.

However for complex objects

In Hyperstack, there are **two exceptions** to this rule:

* An instance of a **Store** \(passed as a param\) is mutable and changes to the state of the Store will cause a re-render
* An instance of a **Model** \(discussed in the Isomorphic section of these docs\) will also case a re-render when changed

In the example below, clicking on the button will cause the Component to re-render \(even though `book` is a `param`\) because `book` is a Model. If `book` were not a Model \(or Store\) then the Component would not re-render.

```ruby
class Likes < HyperComponent
  param :book # book is an instance of the Book model

  render(DIV) do
    P { "#{book.likes.count} likes" }
    BUTTON { "Like" }.on(:click) { book.likes += 1}
  end
end
```

> Note: Non-scalar params \(objects\) which are mutable through their methods are not read only. Care should be taken here as changes made to these objects will **not** cause a re-render of the Component. Specifically, if you pass a non-scalar param into a Component, and modify the internal data of that param, Hyperstack will not be notified to re-render the Component \(as it does not know about the internal structure of your object\). To achieve a re-render in this circumstance you will need to ensure that the parts of your object which are mutable are declared as state in a higher-order parent Component so that data can flow down from the parent to the child as per the React pattern.

### Param Validation

As your app grows it's helpful to ensure that your components are used correctly. We do this by allowing you to specify the expected ruby class of your parameters. When an invalid value is provided for a param, a warning will be shown in the JavaScript console. Note that for performance reasons type checking is only done in development mode. Here is an example showing typical type specifications:

```ruby
class ManyParams < HyperComponent
  param :an_array,         type: [] # or type: Array
  param :a_string,         type: String
  param :array_of_strings, type: [String]
  param :a_hash,           type: Hash
  param :some_class,       type: SomeClass # works with any class
  param :a_string_or_nil,  type: String, allow_nil: true
end
```

Note that if the param can be nil, add `allow_nil: true` to the specification.

### Default Param Values

React lets you define default values for your `params`:

```ruby
class ManyParams < HyperComponent
  param :an_optional_param, default: "hello", type: String, allow_nil: true
```

If no value is provided for `:an_optional_param` it will be given the value `"hello"`

### Params of type Proc

A Ruby `Proc` can be passed to a component like any other object.

```ruby
param :all_done, type: Proc
...
  # typically in an event handler
all_done(data).call
```

Proc params can be optional, using the `default: nil` and `allow_nil: true` options. Invoking a nil proc param will do nothing. This is handy for allowing optional callbacks.

```ruby
class Alarm < HyperComponent
  param :at, type: Time
  param :notify, type: Proc

  after_mount do
    @clock = every(1) do
      if Time.now > at
        notify.call
        @clock.stop
      end
      force_update!
    end
  end

  render do
    "#{Time.now}"
  end
end
```

If for whatever reason you need to get the actual proc instead of calling it use `params.method(*symbol name of method*)`

### Components as Params

You can pass a Component as a `param` and then render it in the receiving Component. To create a Component without rendering it you use `.as_node`. This technique is used extensively in JavaScript libraries.

```ruby
# in the parent Component...
button = MyButton().as_node
ButtonBar(button: button)

class ButtonBar < HyperComponent
  param :button

  render do
    button.render
  end
end
```

`as_node` can be attached to a component or tag, and removes the element from the rendering buffer and returns it. This is useful when you need store an element in some data structure, or passing to a native JS component. When passing an element to another Hyperstack Component `.as_node` will be automatically applied so you normally don't need it.

`render` can be applied to the objects returned by `as_node` and `children` to actually render the node.

```ruby
class Test < HyperComponent
  param :node

  render do
    DIV do
      children.each do |child|
        node.render
        child.render
      end
      node.render
    end
  end
end
```

### Other Params

A common type of React component is one that extends a basic HTML element in a simple way. Often you'll want to copy any HTML attributes passed to your component to the underlying HTML element.

To do this use the `collect_other_params_as` method which will gather all the params you did not declare into a hash. Then you can pass this hash on to the child component

```ruby
class CheckLink < HyperComponent
  collect_other_params_as :attributes
  render do
    # we just pass along any incoming attributes
    a(attributes) { '√ '.span; children.each &:render }
  end
end
# CheckLink(href: "/checked.html")
```

Note: `collect_other_params_as` builds a hash, so you can merge other data in or even delete elements out as needed.
