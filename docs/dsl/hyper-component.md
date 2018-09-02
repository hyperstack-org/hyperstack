# HyperComponent

# Work in progress - ALPHA (docs and code)

## Components DSL Overview

Hyperstack **Components** are implemented in the hyper-component and hyper-react Gems.

Hyperstack Component DSL (Domain Specific Language) is a set of class and instance methods that are used to describe your React components.

The DSL has the following major areas:  

+ The `Hyperstack::Component` class and the equivalent `Hyperstack::Component::Mixin` mixin
+ Class methods or *macros* that describe component class level behaviors
+ The four data accessors methods: `params`, `state`, `mutate`, and `children`
+ The tag and component rendering methods
+ Event handlers
+ Miscellaneous methods

### Hyperstack::Component

Hyperstack Components classes either include `Hyperstack::Component::Mixin` or are subclasses of `Hyperstack::Component`.  

```ruby
class Component < Hyperstack::Component
end

# if subclassing is inappropriate, you can mixin instead
class AnotherComponent
  include Hyperstack::Component::Mixin
end
```

At a minimum every component class must define a `render` macro which returns **one single** child element. That child may in turn have an arbitrarily deep structure.

```ruby
class Component < Hyperstack::Component
  render do
    DIV { } # render an empty div
  end
end
```

You may also include the top level element to be rendered:

```ruby
class Component < Hyperstack::Component
  render(DIV) do
    # everything will be rendered in a div
  end
end
```

To render a component, you reference its class name in the DSL as a method call.  This creates a new instance, passes any parameters proceeds with the component lifecycle.  

```ruby
class AnotherComponent < Hyperstack::Component
  render do
    Component() # ruby syntax requires either () or {} following the class name
  end
end
```

Note that you should never redefine the `new` or `initialize` methods, or call them directly.  The equivalent of `initialize` is the `before_mount` callback.  

### Macros (Class Methods)

Macros specify class wide behaviors.  

```ruby
class MyComponent < Hyperstack::Component
  param ...
  before_mount ...
  after_mount ...
  before_unmount ...
  render ...
end
```  

The `param` macro describes the parameters the component expects.

The `before_mount` macro defines code to be run (a callback) when a component instance is first initialized.

The `after_mount` macro likewise runs after the instance has completed initialization, and is visible in the DOM.

The `before_unmount` macro provides any cleanup actions before the instance is destroyed.

The `render` macro defines the render method.

The available macros are: `render, param, state, mutate, before_mount, after_mount, before_receive_props, before_update, after_update, before_unmount`

### Data Accessor Methods

The four data accessor methods - `params, state, mutate, and children` are instance methods that give access to a component's React specific instance data.

#### Params

The `params` method gives *read-only* access to each of the scalar params passed to the Component.

```ruby
class WelcomeUser < Hyperstack::Component
  param: id

  render(DIV) do
    user = User.find(params.id) # user is mutable
    user.name = "Unknown" unless user.name
    SayHello(name: user.name)
    ...
  end
end

class SayHello < Hyperstack::Component
  param :name, type: String # params.name is immutable and will validate as a String

  render do
    H1 { "Hello #{params.name}" } # notice how you access name through parans
  end
```

A core design concept taken from React is that data flows down to child Components via params and params (called props in React) are immutable.

In Hyperstack, there are two exceptions to this rule:

+ An instance of a Store (passed as a param) is mutable and changes to the state of the Store will cause a re-render
+ An instance of a Model (which is a type of Store) will also case a re-render when changed

In the example below, clicking on the button will cause the Component to re-render (even though `book` is a `param`) because `book` is a Model. If `book` were not a Model then the Component would not re-render.

```ruby
class Likes < Hyperstack::Component
  param :book # book is an instance of the Book model

  render(DIV) do
    P { "#{params.book.likes.count} likes" }
    BUTTON { "Like" }.on(:click) { params.book.likes += 1}
  end
end
```

>Note: Non-scalar params (objects) which are mutable through their methods are not read only. Care should be taken here as changes made to these objects will **not** cause a re-render of the Component. Specifically, if you pass a non-scalar param into a Component, and modify the internal data of that param, Hyperstack will not be notified to re-render the Component (as it does not know about the internal structure of your object). To achieve a re-render in this circumstance you will need to ensure that the parts of your object which are mutable are declared as state in a higher-order parent Component so that data can flow down from the parent to the child as per the React pattern.


#### State

In React (and Hyperstack) state is mutable. Changes to state variables cause Components to re-render and where state is passed into a child Component as a param, it will cause a re-rendering of that child Component. Change flows from a parent to a child - change does not flow upward and this is why params are not mutable.

State variables are (optionally) initialized and accessed through the `state` method.

```ruby
class Counter < Hyperstack::Component
  state count: 0 # optional initialization

  render(DIV) do
    BUTTON { "+" }.on(:click) { mutate.count(state.count + 1) }
    P { state.count.to_s } # note how we access the count variable
  end
end  
```

See [Using State](#using-state) for more information on State.

#### Mutate

The `mutate` method initializes (or updates) a reactive state variable. State variables are like *reactive* instance variables.  They can only be changed using the `mutate` method, and when they change they will cause a re-render.  

```ruby          
before_mount do
  mutate.game_over false
end
```

More on the details of these methods can be found in the [Component API](#top-level-api) section.

### Tag and Component Rendering

```ruby
  ...
    DIV(class: :time) do
      ...
    end
  ...
```

>**Note on coding style:** In the Hyperstack documentation and tutorials we use uppercase HTML elements like `DIV` and `BUTTON` as we believe this makes for greater readability in the code; specifically with code highlighting. If you do not like this you can use lowercase `div` and `button` instead.

HTML such as `DIV, A, SELECT, OPTION` etc. each have a corresponding instance method that will render that tag.  For all the tags the
method call looks like this:

```ruby
tag_name(attribute1 => value1, attribute2 => value2 ...) do
  ...nested tags...
end
```

Each key-value pair in the parameter block is passed down as an attribute to the tag as you would expect, with the exception of the `style` attribute, which takes a hash that is translated to the corresponding style string.

The same rules apply for application defined components, except that the class constant is used to reference the component.

```ruby
Clock(mode: 12)
```

### Using Strings

Strings are treated specially as follows:  

If a render method or a nested tag block returns a string, the string is automatically wrapped in a `<span>` tag.

The code `SPAN { "hello" }` can be shortened to `"hello".SPAN`, likewise for `BR, PARA, TD, TH` tags.

`"some string".BR` generates `<span>some string<span><br/>`


```ruby
Time.now.strftime(FORMATS[state.mode]).SPAN  # generates <span>...current time formatted...</span>
...
  OPTION(value: 12) { "12 Hour Clock" }      # generates <option value=12><span>12 Hour Clock</span></option>
```

### Event Handlers

Event Handlers are attached to tags and components using the `on` method.

```ruby
SELECT ... do
  ...
end.on(:change) do |e|
  mutate.mode(e.target.value.to_i)
end
```

The `on` method takes the event name symbol (note that `onClick` becomes `:click`) and the block is passed the React.js event object.

Event handlers can be chained like so

```ruby
INPUT ... do
  ...
  end.on(:key_up) do |e|
  ...
  end.on(:change) do |e|
  ...
end
```

### Miscellaneous Methods

`force_update!` is a component instance method that causes the component to re-rerender. This method is seldom (if ever) needed.

`as_node` can be attached to a component or tag, and removes the element from the rendering buffer and returns it.   This is useful when you need store an element in some data structure, or passing to a native JS component.  When passing an element to another Hyperstack Component `.as_node` will be automatically applied so you normally don't need it.  

`render` can be applied to the objects returned by `as_node` and `children` to actually render the node.

```ruby
class Test < Hyperstack::Component
  param :node

  render do
    DIV do
      children.each do |child|
        params.node.render
        child.render
      end
      params.node.render
    end
  end
end
```

### Ruby and Hyperstack

A key design goal of the DSL is to make it work seamlessly with the rest of Ruby.  Notice in the above example, the use of constant declaration (`FORMATS`), regular instance variables (`@timer`), and other non-react methods like `every` (an Opal Browser method).  

Component classes can be organized like any other class into a logical module hierarchy or even subclassed.

Likewise the render method can invoke other methods to compute values or even internally build tags.

### DSL Gotchas

There are few gotchas with the DSL you should be aware of:

React has implemented a browser-independent events and DOM system for performance and cross-browser compatibility reasons. We took the opportunity to clean up a few rough edges in browser DOM implementations.

* All DOM properties and attributes (including event handlers) should be snake_cased to be consistent with standard Ruby style. We intentionally break with the spec here since the spec is inconsistent. **However**, `data-*` and `aria-*` attributes [conform to the specs](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes#data-*) and should be lower-cased only.
* The `style` attribute accepts a Hash with camelCased properties rather than a CSS string. This  is more efficient, and prevents XSS security holes.
* All event objects conform to the W3C spec, and all events (including submit) bubble correctly per the W3C spec. See [Event System](#event-handling-and-synthetic-events) for more details.
* The `onChange` event (`on(:change)`) behaves as you would expect it to: whenever a form field is changed this event is fired rather than inconsistently on blur. We intentionally break from existing browser behavior because `onChange` is a misnomer for its behavior and React relies on this event to react to user input in real time.
* Form input attributes such as `value` and `checked`, as well as `textarea`.

#### HTML Entities

If you want to display an HTML entity within dynamic content, you will run into double escaping issues as React.js escapes all the strings you are displaying in order to prevent a wide range of XSS attacks by default.

```ruby
DIV {'First &middot; Second' }
  # Bad: It displays "First &middot; Second"
```

To workaround this you have to insert raw HTML.

```ruby
DIV(dangerously_set_inner_HTML: { __html: "First &middot; Second"})
```

#### Custom HTML Attributes

If you pass properties to native HTML elements that do not exist in the HTML specification, React will not render them. If you want to use a custom attribute, you should prefix it with `data-`.

```ruby
DIV("data-custom-attribute" => "foo")
```

[Web Accessibility](http://www.w3.org/WAI/intro/aria) attributes starting with `aria-` will be rendered properly.

```ruby
DIV("aria-hidden" => true)
```

#### Invoking Application Components

When invoking a custom component you must have a (possibly empty) parameter list or (possibly empty) block.  This is not necessary
with standard html tags.

```ruby
MyCustomComponent()  # okay
MyCustomComponent {} # okay
MyCustomComponent    # breaks
br                   # okay
```

## Components and State

### Using State

#### A Simple Example

<div class="codemirror-live-edit"
  data-heading="A simple Component rendering state"
  data-rows=12
  data-top-level-component="LikeButton">
<pre>
class LikeButton < Hyperstack::Component

  render(DIV) do
    P do
      "You #{state.liked ? 'like' : 'haven\'t liked'} this. Click to toggle."
    end.on(:click) do
      mutate.liked !state.liked
    end
  end
end
</pre></div>


### Components are Just State Machines

React thinks of UIs as simple state machines. By thinking of a UI as being in various states and rendering those states, it's easy to keep your UI consistent.

In React, you simply update a component's state, and then the new UI will be rendered on this new state. React takes care of updating the DOM for you in the most efficient way.

### How State Works

To change a state variable you use `mutate.state_variable` and pass the new value.  For example `mutate.liked(!state.like)` *gets* the current value of like, toggles it, and then *updates* it.  This in turn causes the component to be rerendered. For more details on how this works, and the full syntax of the update method see [the component API reference](#top-level-api)

### What Components Should Have State?

Most of your components should simply take some params and render based on their value. However, sometimes you need to respond to user input, a server request or the passage of time. For this you use state.

**Try to keep as many of your components as possible stateless.** By doing this you'll isolate the state to its most logical place and minimize redundancy, making it easier to reason about your application.

A common pattern is to create several stateless components that just render data, and have a stateful component above them in the hierarchy that passes its state to its children via `params`. The stateful component encapsulates all of the interaction logic, while the stateless components take care of rendering data in a declarative way.

### What *Should* Go in State?

**State should contain data that a component's event handlers, timers, or http requests may change and trigger a UI update.**

When building a stateful component, think about the minimal possible representation of its state, and only store those properties in `state`.  Add to your class methods to compute higher level values from your state variables.  Avoid adding redundant or computed values as state variables as
these values must then be kept in sync whenever state changes.

### What *Shouldn't* Go in State?

`state` should only contain the minimal amount of data needed to represent your UI's state. As such, it should not contain:

* **Computed data:** Don't worry about precomputing values based on state — it's easier to ensure that your UI is consistent if you do all computation during rendering.  For example, if you have an array of list items in state and you want to render the count as a string, simply render `"#{state.list_items.length} list items'` in your `render` method rather than storing the count as another state.
* **Data that does not effect rendering:** For example handles on timers, that need to be cleaned up when a component unmounts should go
in plain old instance variables.

## Multiple Components

So far, we've looked at how to write a single component to display data and handle user input. Next let's examine one of React's finest features: composability.

### Motivation: Separation of Concerns

By building modular components that reuse other components with well-defined interfaces, you get much of the same benefits that you get by using functions or classes. Specifically you can *separate the different concerns* of your app however you please simply by building new components. By building a custom component library for your application, you are expressing your UI in a way that best fits your domain.

### Composition Example

Let's create a simple Avatar component which shows a profile picture and username using the Facebook Graph API.

```ruby
class Avatar < Hyperstack::Component
  param :user_name
  render(DIV) do
    ProfilePic  user_name: params.user_name
    ProfileLink user_name: params.user_name
  end
end

class ProfilePic < Hyperstack::Component
  param :user_name
  render do
    IMG src: "https://graph.facebook.com/#{params.user_name}/picture"
  end
end

class ProfileLink < Hyperstack::Component
  param :user_name
  render do
    A href: "https://www.facebook.com/#{params.user_name}" do
      params.user_name
    end
  end
end
```

### Ownership

In the above example, instances of `Avatar` *own* instances of `ProfilePic` and `ProfileLink`. In React, **an owner is the component that sets the `params` of other components**. More formally, if a component `X` is created in component `Y`'s `render` method, it is said that `X` is *owned by* `Y`. As discussed earlier, a component cannot mutate its `params` — they are always consistent with what its owner sets them to. This fundamental invariant leads to UIs that are guaranteed to be consistent.

It's important to draw a distinction between the owner-ownee relationship and the parent-child relationship. The owner-ownee relationship is specific to React, while the parent-child relationship is simply the one you know and love from the DOM. In the example above, `Avatar` owns the `div`, `ProfilePic` and `ProfileLink` instances, and `div` is the **parent** (but not owner) of the `ProfilePic` and `ProfileLink` instances.

### Children

When you create a React component instance, you can include additional React components or JavaScript expressions between the opening and closing tags like this:

```ruby
Parent { Child() }
```

`Parent` can iterate over its children by accessing its `children` method.

### Child Reconciliation

**Reconciliation is the process by which React updates the DOM with each new render pass.** In general, children are reconciled according to the order in which they are rendered. For example, suppose we have the following render method displaying a list of items.  On each pass
the items will be completely rerendered:

```ruby
render do
  params.items.each do |item|
    para do
      item[:text]
    end
  end
end
```

What if the first time items was `[{text: "foo"}, {text: "bar"}]`, and the second time items was `[{text: "bar"}]`?
Intuitively, the paragraph `<p>foo</p>` was removed. Instead, React will reconcile the DOM by changing the text content of the first child and destroying the last child. React reconciles according to the *order* of the children.

### Stateful Children

For most components, this is not a big deal. However, for stateful components that maintain data in `state` across render passes, this can be very problematic.

In most cases, this can be sidestepped by hiding elements based on some property change:

```ruby
render do
  state.items.each do |item|
    PARA(style: {display: item[:some_property] == "some state" ? :block : :none}) do
      item[:text]
    end
  end
end
```

### Dynamic Children

The situation gets more complicated when the children are shuffled around (as in search results) or if new components are added onto the front of the list (as in streams). In these cases where the identity and state of each child must be maintained across render passes, you can uniquely identify each child by assigning it a `key`:

```ruby
  param :results, type: [Hash] # each result is a hash of the form {id: ..., text: ....}
  render do
    OL do
      params.results.each do |result|
        LI(key: result[:id]) { result[:text] }
      end
    end
  end
```

When React reconciles the keyed children, it will ensure that any child with `key` will be reordered (instead of clobbered) or destroyed (instead of reused).

The `key` should *always* be supplied directly to the components in the array, not to the container HTML child of each component in the array:

```ruby
# WRONG!
class ListItemWrapper < Hyperstack::Component
  param :data
  render do
    LI(key: params.data[:id]) { params.data[:text] }
  end
end    
class MyComponent < Hyperstack::Component
  param :results
  render do
    UL do
      params.result.each do |result|
        ListItemWrapper data: result
      end
    end
  end
end
```
```ruby
# CORRECT
class ListItemWrapper < Hyperstack::Component
  param :data
  render do
    LI { params.data[:text] }
  end
end
class MyComponent < Hyperstack::Component
  param :results
  render do
    UL do
      params.result.each do |result|
        ListItemWrapper key: result[:id], data: result
      end
    end
  end
end
```

### Data Flow

In React, data flows from owner to owned component through the params as discussed above. This is effectively one-way data binding: owners bind their owned component's param to some value the owner has computed based on its `params` or `state`. Since this process happens recursively, data changes are automatically reflected everywhere they are used.

### Stores

Managing state between components is best done using Stores as many Components can access one store. This saves passing data btween Components. Please see the [Store documentation](/docs/stores/overview) for details.

### Reusable Components

When designing interfaces, break down the common design elements (buttons, form fields, layout components, etc.) into reusable components with well-defined interfaces. That way, the next time you need to build some UI, you can write much less code. This means faster development time, fewer bugs, and fewer bytes down the wire.

### Param Validation

As your app grows it's helpful to ensure that your components are used correctly. We do this by allowing you to specify the expected ruby class of your parameters. When an invalid value is provided for a param, a warning will be shown in the JavaScript console. Note that for performance reasons type checking is only done in development mode. Here is an example showing typical type specifications:

```ruby
class ManyParams < Hyperstack::Component
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
class ManyParams < Hyperstack::Component
  param :an_optional_param, default: "hello", type: String, allow_nil: true
```

If no value is provided for `:an_optional_param` it will be given the value `"hello"`

### Params of type Proc

A Ruby `Proc` can be passed to a component like any other object.  The `param` macro treats params declared as type `Proc` specially, and will automatically call the proc when the param name is used on the params method.

```ruby
param :all_done, type: Proc
...
  # typically in an event handler
params.all_done(data) # instead of params.all_done.call(data)
```

Proc params can be optional, using the `default: nil` and `allow_nil: true` options.  Invoking a nil proc param will do nothing.  This is handy for allowing optional callbacks.

### Other Params

A common type of React component is one that extends a basic HTML element in a simple way. Often you'll want to copy any HTML attributes passed to your component to the underlying HTML element.

To do this use the `collect_other_params_as` macro which will gather all the params you did not declare into a hash. Then you can pass this hash on to the child component

```ruby
class CheckLink < Hyperstack::Component
  collect_other_params_as :attributes
  render do
    # we just pass along any incoming attributes
    a(attributes) { '√ '.span; children.each &:render }
  end
end
# CheckLink(href: "/checked.html")
```

Note: `collect_other_params_as` builds a hash, so you can merge other data in or even delete elements out as needed.


### Mixins and Inheritance

Ruby has a rich set of mechanisms enabling code reuse, and Hyperstack is intended to be a team player in your Ruby application.  Components can be subclassed, and they can include (or mixin) other modules.  You can also create a component by including `Hyperstack::Component::Mixin` which allows a class to inherit from some other non-react class, and then mixin the React DSL.

```ruby
  # make a SuperFoo react component class
  class Foo < SuperFoo
    include Hyperstack::Component::Mixin
  end
```

One common use case is a component wanting to update itself on a time interval. It's easy to use the kernel method `every`, but it's important to cancel your interval when you don't need it anymore to save memory. React provides [lifecycle methods](/docs/working-with-the-browser.html#component-lifecycle) that let you know when a component is about to be created or destroyed. Let's create a simple mixin that uses these methods to provide a React friendly `every` function that will automatically get cleaned up when your component is destroyed.


<div class="codemirror-live-edit"
  data-heading="Using state"
  data-rows=33
  data-top-level-component="TickTock">
<pre>
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

class TickTock < Hyperstack::Component
  include ReactInterval

  before_mount do
    state.seconds! 0
  end

  after_mount do
    every(1) { mutate.seconds state.seconds+1}
  end

  render(DIV) do
    "Hyperstack has been running for #{state.seconds} seconds".para
  end
end
</pre></div>

Notice that TickTock effectively has two before_mount callbacks, one that is called to initialize the `@intervals` array and another to initialize `state.seconds`

## Lifecycle Callbacks

A component may define callbacks for each phase of the components lifecycle:

* `before_mount`
* `render`
* `after_mount`
* `before_receive_props`
* `before_update`
* `after_update`
* `before_unmount`

All the callback macros may take a block or the name of an instance method to be called.

```ruby
class AComponent < Hyperstack::Component
  before_mount do
    # initialize stuff here
  end
  before_unmount :cleanup  # call the cleanup method before unmounting
  ...
end
```

Except for the render callback, multiple callbacks may be defined for each lifecycle phase, and will be executed in the order defined, and from most deeply nested subclass outwards.

Details on the component lifecycle is described [here](docs/component-specs.html)

### The param macro

Within a React Component the `param` macro is used to define the parameter signature of the component.  You can think of params as
the values that would normally be sent to the instance's `initialize` method, but with the difference that a React Component gets new parameters when it is rerendered.  

The param macro has the following syntax:

```ruby
param symbol, ...options... # or
param symbol => default_value, ...options...
```

Available options are `:default_value => ...any value...` and `:type => ...class_spec...`
where class_spec is either a class name, or `[]` (shorthand for Array), or `[ClassName]` (meaning array of `ClassName`.)

Note that the default value can be specied either as the hash value of the symbol, or explicitly using the `:default_value` key.

Examples:

```ruby
param :foo # declares that we must be provided with a parameter foo when the component is instantiated or re-rerendered.
param :foo => "some default"        # declares that foo is optional, and if not present the value "some default" will be used.
param foo: "some default"           # same as above using ruby 1.9 JSON style syntax
param :foo, default: "some default" # same as above but uses explicit default key
param :foo, type: String            # foo is required and must be of type String
param :foo, type: [String]          # foo is required and must be an array of Strings
param foo: [], type: [String]       # foo must be an array of strings, and has a default value of the empty array.
```

#### Accessing param values

The component instance method `params` gives access to all declared params.  So for example

```ruby
class Hello < Hyperstack::Component
  param visitor: "World", type: String

  render do
    "Hello #{params.visitor}"
  end
end
```

#### Params of type Proc

A param of type proc (i.e. `param :update, type: Proc`) gets special treatment that will directly
call the proc when the param is accessed.

```ruby
class Alarm < Hyperstack::Component
  param :at, type: Time
  param :notify, type: Proc

  after_mount do
    @clock = every(1) do
      if Time.now > params.at
        params.notify
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

### The state instance method

React state variables are *reactive* component instance variables that cause rerendering when they change.

State variables are accessed via the `state` instance method which works like the `params` method. Like normal instance variables, state variables are created when they are first accessed, so there is no explicit declaration.  

To access the value of a state variable `foo` you would say `state.foo`.  

To initialize or update a state variable you use `mutate.` followed by its name.  For example `mutate.foo []` would initialize `foo` to an empty array.  Unlike the assignment operator, the mutate method returns the current value (before it is changed.)

Often state variables have complex values with their own internal state, an array for example.  The problem is as you push new values onto the array you are not changing the object pointed to by the state variable, but its internal state.

To handle this use the same `mutate` prefix with **no** parameter, and then apply any update methods to the resulting value.  The underlying value will be updated, **and** the underlying system will be notified that a state change has occurred.

For example:

```ruby
  mutate.foo []    # initialize foo (returns nil)
    #...later...
  mutate.foo << 12  # push 12 onto foo's array
    #...or...
  mutate.foo {}
  mutate.foo[:house => :boat]
```

The rule is simple:  anytime you are updating a state variable use `mutate`.
<br><br>

> #### Tell Me How That Works???
>
> A state variables mutate method can optionally accept one parameter.  If a parameter is passed, then the method will 1) save the current value, 2) update the value to the passed parameter, 3) update the underlying react.js state object, 4) return the saved value.

#### The force_update! method

The `force_update!` instance method causes the component to re-render.  Usually this is not necessary as rendering will occur when state variables change, or new params are passed.  For a good example of using `force_update!` see the `Alarm` component above.  In this case there is no reason to have a state track of the time separately, so we just call `force_update!` every second.

#### The dom_node method

Returns the dom_node that this component instance is mounted to.  Typically used in the `after_mount` callback to setup linkages to external libraries.

#### The children method

Along with params components may be passed a block which is used to build the components children.

The instance method `children` returns an enumerable that is used to access the unrendered children of a component.

<div class="codemirror-live-edit"
  data-heading="The children method"
  data-rows=20
  data-top-level-component="Indenter">
<pre>
class IndentEachLine < Hyperstack::Component
  param by: 20, type: Integer

  render(DIV) do
    children.each_with_index do |child, i|
      child.render(style: {"margin-left" => params.by*i})
    end
  end
end

class Indenter < Hyperstack::Component
  render(DIV) do
    IndentEachLine(by: 100) do
      DIV {"Line 1"}
      DIV {"Line 2"}
      DIV {"Line 3"}
    end
  end
end
</pre></div>

### Lifecycle Methods

A component class may define callbacks for  specific points in a component's lifecycle.

#### Rendering

The lifecycle revolves around rendering the component.  As the state or parameters of a component changes, its render method will be called to generate the new HTML.  The rest of the callbacks hook into the lifecycle before or after rendering.

For reasons described below Hyperstack provides a render callback to simplify defining the render method:

```ruby
render do ....
end
```

The render callback will generate the components render method.  It may optionally take the container component and params:

```ruby
render(:DIV, class: 'my-class') do
  ...
end
```

which would be equivilent to:

```ruby
render do
  DIV(class: 'my-class') do
    ...
  end
end
```

The purpose of the render callback is syntactic.  Many components consist of a static outer container with possibly some parameters, and most component's render method by necessity will be longer than the normal *10 line* ruby style guideline.  The render call back solves both these problems by allowing the outer container to be specified as part of the callback parameter (which reads very nicely) and because the render code is now specified as a block you avoid the 10 line limitation, while encouraging the rest of your methods to adhere to normal ruby style guides

#### Before Mounting (first render)

```ruby
before_mount do ...
end
```

Invoked once when the component is first instantiated, immediately before the initial rendering occurs. This is where state variables should
be initialized.

This is the only life cycle method that is called during `render_to_string` used in server side pre-rendering.

#### After Mounting (first render)

```ruby
after_mount do ...
end
```

Invoked once, only on the client (not on the server), immediately after the initial rendering occurs. At this point in the lifecycle, you can access any refs to your children (e.g., to access the underlying DOM representation). The `after_mount` callbacks of children components are invoked before that of parent components.

If you want to integrate with other JavaScript frameworks, set timers using the `after` or `every` methods, or send AJAX requests, perform those operations in this method.  Attempting to perform such operations in before_mount will cause errors during prerendering because none of these operations are available in the server environment.


#### Before Receiving New Params

```ruby
before_receive_props do |new_params_hash| ...
end
```

Invoked when a component is receiving *new* params (React.js props). This method is not called for the initial render.

Use this as an opportunity to react to a prop transition before `render` is called by updating any instance or state variables. The
new_props block parameter contains a hash of the new values.

```ruby
before_receive_props do |next_props|
  state.likes_increasing! (next_props[:like_count] > params.like_count)
end
```

> Note:
>
> There is no analogous method `before_receive_state`. An incoming param may cause a state change, but the opposite is not true. If you need to perform operations in response to a state change, use `before_update`.


#### Controlling Updates

Normally Hyperstack will only update a component if some state variable or param has changed.  To override this behavior you can redefine the `should_component_update?` instance method.  For example, assume that we have a state called `funky` that for whatever reason, we
cannot update using the normal `state.funky!` update method.  So what we can do is override `should_component_update?` call `super`, and then double check if the `funky` has changed by doing an explicit comparison.

```ruby
class RerenderMore < Hyperstack::Component
  def should_component_update?(new_params_hash, new_state_hash)
    super || new_state_hash[:funky] != state.funky
  end
end
```

Why would this happen?  Most likely there is integration between new Hyperstack Components and other data structures being maintained outside of Hyperstack, and so we have to do some explicit comparisons to detect the state change.

Note that `should_component_update?` is not called for the initial render or when `force_update!` is used.

> Note to react.js readers.  Essentially Hyperstack assumes components are "well behaved" in the sense that all state changes
> will be explicitly declared using the state update ("!") method when changing state.  This gives similar behavior to a
> "pure" component without the possible performance penalties.
> To achieve the standard react.js behavior add this line to your class `def should_component_update?; true; end`

#### Before Updating (re-rendering)

```ruby
before_update do ...
end
```

Invoked immediately before rendering when new params or state are bein#g received.  


#### After Updating (re-rendering)

```ruby
after_update do ...
end
```

Invoked immediately after the component's updates are flushed to the DOM. This method is not called for the initial render.

Use this as an opportunity to operate on the DOM when the component has been updated.

#### Unmounting

```ruby
before_unmount do ...
end
```

Invoked immediately before a component is unmounted from the DOM.

Perform any necessary cleanup in this method, such as invalidating timers or cleaning up any DOM elements that were created in the `after_mount` callback.

### Event Handlers

#### Event Handling and Synthetic Events

With React you attach event handlers to elements using the `on` method. React ensures that all events behave identically in IE8 and above by implementing a synthetic event system. That is, React knows how to bubble and capture events according to the spec, and the events passed to your event handler are guaranteed to be consistent with [the W3C spec](http://www.w3.org/TR/DOM-Level-3-Events/), regardless of which browser you're using.

#### Under the Hood: Event Delegation

React doesn't actually attach event handlers to the nodes themselves. When React starts up, it starts listening for all events at the top level using a single event listener. When a component is mounted or unmounted, the event handlers are simply added or removed from an internal mapping. When an event occurs, React knows how to dispatch it using this mapping. When there are no event handlers left in the mapping, React's event handlers are simple no-ops. To learn more about why this is fast, see [David Walsh's excellent blog post](http://davidwalsh.name/event-delegate).

#### React::Event

Your event handlers will be passed instances of `React::Event`, a wrapper around react.js's `SyntheticEvent` which in turn is a cross browser wrapper around the browser's native event. It has the same interface as the browser's native event, including `stopPropagation()` and `preventDefault()`, except the events work identically across all browsers.

For example:

```ruby
class YouSaid < Hyperstack::Component

  render(DIV) do
    INPUT(value: state.value).
    on(:key_down) do |e|
      alert "You said: #{state.value}" if e.key_code == 13
    end.
    on(:change) do |e|
      mutate.value e.target.value
    end
  end
end
```

If you find that you need the underlying browser event for some reason use the `native_event`.  

In the following responses shown as (native ...) indicate the value returned is a native object with an Opal wrapper.  In some cases there will be opal methods available (i.e. for native DOMNode values) and in other cases you will have to convert to the native value
with `.to_n` and then use javascript directly.

Every `React::Event` has the following methods:

```ruby
bubbles                -> Boolean
cancelable             -> Boolean
current_target         -> (native DOM node)
default_prevented      -> Boolean
event_phase            -> Integer
is_trusted             -> Boolean
native_event           -> (native Event)
prevent_default        -> Proc
is_default_prevented   -> Boolean
stop_propagation       -> Proc
is_propagation_stopped -> Boolean
target                 -> (native DOMEventTarget)
timestamp              -> Integer (use Time.at to convert to Time)
type                   -> String
```

#### Event pooling

The underlying React `SyntheticEvent` is pooled. This means that the `SyntheticEvent` object will be reused and all properties will be nullified after the event callback has been invoked. This is for performance reasons. As such, you cannot access the event in an asynchronous way.

#### Supported Events

React normalizes events so that they have consistent properties across
different browsers.


#### Clipboard Events

Event names:

```ruby
:copy, :cut, :paste
```

Available Methods:

```ruby
clipboard_data -> (native DOMDataTransfer)
```

#### Composition Events (not tested)

Event names:

```ruby
:composition_end, :composition_start, :composition_update
```

Available Methods:

```ruby
data -> String
```

#### Keyboard Events

Event names:

```ruby
:key_down, :key_press, :key_up
```

Available Methods:

```ruby
alt_key                 -> Boolean
char_code               -> Integer
ctrl_key                -> Boolean
get_modifier_state(key) -> Boolean (i.e. get_modifier_key(:Shift)
key                     -> String
key_code                -> Integer
locale                  -> String
location                -> Integer
meta_key                -> Boolean
repeat                  -> Boolean
shift_key               -> Boolean
which                   -> Integer
```


#### Focus Events

Event names:

```ruby
:focus, :blur
```

Available Methods:

```ruby
related_target -> (Native DOMEventTarget)
```

These focus events work on all elements in the React DOM, not just form elements.

#### Form Events

Event names:

```ruby
:change, :input, :submit
```

#### Mouse Events

Event names:

```ruby
:click, :context_menu, :double_click, :drag, :drag_end, :drag_enter, :drag_exit
:drag_leave, :drag_over, :drag_start, :drop, :mouse_down, :mouse_enter,
:mouse_leave, :mouse_move, :mouse_out, :mouse_over, :mouse_up
```

The `:mouse_enter` and `:mouse_leave` events propagate from the element being left to the one being entered instead of ordinary bubbling and do not have a capture phase.

Available Methods:

```ruby
alt_key                 -> Boolean
button                  -> Integer
buttons                 -> Integer
client_x                -> Integer
number client_y         -> Integer
ctrl_key                -> Boolean
get_modifier_state(key) -> Boolean
meta_key                -> Boolean
page_x                  -> Integer
page_y                  -> Integer
related_target          -> (Native DOMEventTarget)
screen_x                -> Integer
screen_y                -> Integer
shift_key               -> Boolean
```

#### Drag and Drop example

Here is a Hyperstack version of this [w3schools.com](https://www.w3schools.com/html/html5_draganddrop.asp) example:

```ruby
DIV(id: "div1", style: {width: 350, height: 70, padding: 10, border: '1px solid #aaaaaa'})
  .on(:drop) do |ev|
    ev.prevent_default
    data = `#{ev.native_event}.native.dataTransfer.getData("text")`
    `#{ev.target}.native.appendChild(document.getElementById(data))`
  end
  .on(:drag_over) { |ev| ev.prevent_default }

IMG(id: "drag1", src: "https://www.w3schools.com/html/img_logo.gif", draggable: "true", width: 336, height: 69)
  .on(:drag_start) do |ev|
    `#{ev.native_event}.native.dataTransfer.setData("text", #{ev.target}.native.id)`
  end
```

#### Selection events

Event names:

```ruby
onSelect
```


#### Touch events

Event names:

```ruby
:touch_cancel, :touch_end, :touch_move, :touch_start
```

Available Methods:

```ruby
alt_key                 -> Boolean
changed_touches         -> (Native DOMTouchList)
ctrl_key                -> Boolean
get_modifier_state(key) -> Boolean
meta_key                -> Boolean
shift_key               -> Boolean
target_touches          -> (Native DOMTouchList)
touches                 -> (Native DomTouchList)
```

#### UI Events

Event names:

```ruby
:scroll
```

Available Methods:

```ruby
detail -> Integer
view   -> (Native DOMAbstractView)
```


#### Wheel Events

Event names:

```ruby
wheel
```

Available Methods:

```ruby
delta_mode -> Integer
delta_x    -> Integer
delta_y    -> Integer
delta_z    -> Integer
```

#### Media Events

Event names:

```ruby
:abort, :can_play, :can_play_through, :duration_change,:emptied, :encrypted, :ended, :error, :loaded_data,
:loaded_metadata, :load_start, :pause, :play, :playing, :progress, :rate_change, :seeked, :seeking, :stalled,
:on_suspend, :time_update, :volume_change, :waiting
```

#### Image Events

Event names:

```ruby
:load, :error
```

### Elements and Rendering

#### React.create_element

A React Element is a component class, a set of parameters, and a group of children.  When an element is rendered the parameters and used to initialize a new instance of the component.

`React.create_element` creates a new element.  It takes either the component class, or a string (representing a built in tag such as div, or span), the parameters (properties) to be passed to the element, and optionally a block that will be evaluated to build the enclosed children elements

```ruby
React.create_element("div", prop1: "foo", prop2: 12) { para { "hello" }; para { "goodby" } )
  # when rendered will generates <div prop1="foo" prop2="12"><p>hello</p><p>goodby</p></div>
```

**You almost never need to directly call `create_element`, the DSL, Rails, and jQuery interfaces take care of this for you.**

```ruby
# dsl - creates element and pushes it into the rendering buffer
MyComponent(...params...) { ...optional children... }

# dsl - component will NOT be placed in the rendering buffer
MyComponent(...params...) { ... }.as_node

# in a rails controller - renders component as the view
render_component("MyComponent", ...params...)

# in a rails view helper - renders component into the view (like a partial)
react_component("MyComponent", ...)

# from jQuery (Note Element is the Opal jQuery wrapper, not be confused with React::Element)
Element['#container'].render { MyComponent(...params...) { ...optional children... } }  
```

#### React.is\_valid\_element?

```ruby
is_valid_element?(object)
```

Verifies `object` is a valid react element.  Note that `React::Element` wraps the React.js native class,
`React.is_valid_element?` returns true for both classes unlike `object.is_a? React::Element`

#### React.render

```ruby
React.render(element, container) { puts "element rendered" }
```

Render an `element` into the DOM in the supplied `container` and return a [reference](/docs/more-about-refs.html) to the component.

The container can either be a DOM node or a jQuery selector (i.e. Element['#container']) in which case the first element is the container.

If the element was previously rendered into `container`, this will perform an update on it and only mutate the DOM as necessary to reflect the latest React component.

If the optional block is provided, it will be executed after the component is rendered or updated.

> Note:
>
> `React.render()` controls the contents of the container node you pass in. Any existing DOM elements inside are replaced when first called. Later calls use React’s DOM diffing algorithm for efficient updates.
>
> `React.render()` does not modify the container node (only modifies the children of the container). In the future, it may be possible to insert a component to an existing DOM node without overwriting the existing children.


#### React.unmount\_component\_at\_node

```ruby
React.unmount_component_at_node(container)
```

Remove a mounted React component from the DOM and clean up its event handlers and state. If no component was mounted in the container, calling this function does nothing. Returns `true` if a component was unmounted and `false` if there was no component to unmount.

#### React.render\_to\_string

```ruby
React.render_to_string(element)
```

Render an element to its initial HTML. This is should only be used on the server for prerendering content. React will return a string containing the HTML. You can use this method to generate HTML on the server and send the markup down on the initial request for faster page loads and to allow search engines to crawl your pages for SEO purposes.

If you call `React.render` on a node that already has this server-rendered markup, React will preserve it and only attach event handlers, allowing you to have a very performant first-load experience.

If you are using rails, then the prerendering functions are automatically performed.  Otherwise you can use `render_to_string` to build your own prerendering system.


#### React.render\_to\_static\_markup

```ruby
React.render_to_static_markup(element)
```

Similar to `render_to_string`, except this doesn't create extra DOM attributes such as `data-react-id`, that React uses internally. This is useful if you want to use React as a simple static page generator, as stripping away the extra attributes can save lots of bytes.

### Using Javascript Components

While it is quite possible to develop large applications purely in Hyperstack Components with a ruby back end like rails, you may eventually find you want to use some pre-existing React Javascript library.   Or you may be working with an existing React-JS application, and want to just start adding some Hyperstack Components.

Either way you are going to need to import Javascript components into the Hyperstack namespace. Hyperstack provides both manual and automatic mechanisms to do this depending on the level of control you need.

#### Importing Components

Lets say you have an existing React Component written in javascript that you would like to access from Hyperstack.  

Here is a simple hello world component:

```javascript
window.SayHello = React.createClass({
  displayName: "SayHello",
  render: function render() {
    return React.createElement("div", null, "Hello ", this.props.name);
  }
})
```

Assuming that this component is loaded some place in your assets, you can then access this from Hyperstack by creating a wrapper Component:

```ruby
class SayHello < Hyperstack::Component
  imports 'SayHello'
end

class MyBigApp < Hyperstack::Component
  render(DIV) do
    # SayHello will now act like any other Hyperstack component
    SayHello name: 'Matz'
  end
end
```

The `imports` directive takes a string (or a symbol) and will simply evaluate it and check to make sure that the value looks like a React component, and then set the underlying native component to point to the imported component.


#### Importing Libraries

Many React components come in libraries.  The `ReactBootstrap` library is one example.  You can import the whole library at once using the `React::NativeLibrary` class.  Assuming that you have initialized `ReactBootstrap` elsewhere, this is how you would bring it into Hyperstack.

```ruby
class RBS < React::NativeLibrary
  imports 'ReactBootstrap'
end
```

We can now access our bootstrap components as components defined within the RBS scope:

```ruby
class Show < Hyperstack::Component

  def say_hello(i)
    alert "Hello from number #{i}"
  end

  render RBS::Navbar, bsStyle: :inverse do
    RBS::Nav() do
      RBS::NavbarBrand() do
        A(href: '#') { 'Hyperstack Showcase' }
      end
      RBS::NavDropdown(eventKey: 1, title: 'Things', id: :drop_down) do
        (1..5).each do |n|
          RBS::MenuItem(href: '#', key: n, eventKey: "1.#{n}") do
            "Number #{n}"
          end.on(:click) { say_hello(n) }
        end
      end
    end
  end
end
```

Besides the `imports` directive, `React::NativeLibrary` also provides a rename directive that takes pairs in the form `oldname => newname`.  For example:

```ruby
  rename 'NavDropdown' => 'NavDD', 'Navbar' => 'NavBar', 'NavbarBrand' => 'NavBarBrand'
```

`React::NativeLibrary` will import components that may be deeply nested in the library.  For example consider a component was defined as `MyLibrary.MySubLibrary.MyComponent`:

```ruby
class MyLib < React::NativeLibrary
  imports 'MyLibrary'
end

class App < React::NativeLibrary
  render do  
    ...
    MyLib::MySubLibrary::MyComponent ...
    ...
  end
end
```

Note that the `rename` directive can be used to rename both components and sublibraries, giving you full control over the ruby names of the components and libraries.

#### Auto Import

If you use a lot of libraries and are using a Javascript tool chain with Webpack, having to import the libraries in both Hyperstack and Webpack is redundant and just hard work.

Instead you can opt-in for *auto importing* Javascript components into Hyperstack as you need them.  Simply `require hyper-react/auto-import` immediately after you `require hyper-react`.  

Now you do not have to use component `imports` directive or `React::NativeLibrary` unless you need to rename a component.

In Ruby all module and class names normally begin with an uppercase letter.  However in Javascript this is not always the case, so the auto import will first try the Javascript name that exactly matches the Ruby name, and if that fails it will try the same name with the first character downcased.  For example

`MyComponent` will first try `MyComponent` in the Javascript name space, then `myComponent`.

Likewise MyLib::MyComponent would match any of the following in the Javascript namespace: `MyLib.MyComponent`, `myLib.MyComponent`, `MyLib.myComponent`, `myLib.myComponent`

*How it works:  The first time Ruby hits a native library or component name, the constant value will not be defined.  This will trigger a lookup in the javascript name space for the matching component or library name.  This will generate either a new subclass of Hyperstack::Component or React::NativeLibrary that imports the javascript object, and no further lookups will be needed.*

#### Including React Source  

If you are in the business of importing components with a tool like Webpack, then you will need to let Webpack (or whatever dependency manager you are using) take care of including the React source code.  Just make sure that you are *not* including it on the ruby side of things. Hyperstack is currently tested with React versions 13, 14, and 15, so its not sensitive to the version you use.

However it gets a little tricky if you are using the react-rails gem.  Each version of this gem depends on a specific version of React, and so you will need to manually declare this dependency in your Javascript dependency manager.  Consult this [table](https://github.com/reactjs/react-rails/blob/master/VERSIONS.md) to determine which version of React you need. For example assuming you are using `npm` to install modules and you are using version 1.7.2 of react-rails you would say something like this:

```bash
npm install react@15.0.2 react-dom@15.0.2 --save
```  

#### Using Webpack

Just a word on Webpack: If you a Ruby developer who is new to using Javascript libraries then we recommend using Webpack to manage javascript component dependencies.  Webpack is essentially bundler for Javascript. Please see our Tutorials section for more information.

There are also good tutorials on integrating Webpack with existing rails apps a google search away.

### Server-side rendering (or Prerendering)

**Prerendering is controllable at three levels:**

+ In the rails Hyperstack initializer you can say:

 ```ruby
 Hyperstack.configuration do |config|
   config.prerendering = :on # :off by default
 end
 ```

+ In a route you can override the config setting by setting a default for Hyperstack_prerendering:

```ruby
get '/some_page', to: 'Hyperstack#some_page', defaults: {Hyperstack_prerendering: :off} # or :on
```

This allows you to override the prerendering option for specific pages. For example the application may have prererendering off by default (via the config setting) but you can still turn it on for a specific page.

+ You can override the route, and config setting using the Hyperstack-prerendering query param:

```html
http://localhost:3000/my_hyper_app/some_page?Hyperstack-prerendering=off
```

This is useful for development and testing

NOTE: in the route you say Hyperstack_prererendering but in the query string its Hyperstack-prerendering (underscore vs. dash). This is because of rails security protection when using defaults.

### Further Reading

**Note:** The Hyperstack gems have recently been renamed. The links below will take you to the correct Github projects but you might find the name of the project does not quite match the name of the gem on this page. Hyperstack Components were previously known as HyperReact or Reactrb.

#### Other Hyperstack tutorials and examples
+ [Hyperstack Tutorials](http://ruby-Hyperstack.io/tutorials/)

#### React under the covers

Hyperstack Components and friends are in most cases simple DSL Ruby wrappers to the underlying native JavaScript libraries and React Components. It is really important to have a solid grip on how these technologies work to complement your understanding of Hyperstack. Most searches for help on Google will take you to examples written in JSX or ES6 JavaScript but you will learn over time to translate this to Hyperstack equivalents. To make headway with Hyperstack you do need a solid understanding of the underlying philosophy of React and its component based architecture. The 'Thinking in React' tutorial below is an excellent place to start.

+ [Thinking in React](https://facebook.github.io/react/docs/thinking-in-react.html)
+ [React](https://facebook.github.io/react/docs/getting-started.html)
+ [React Router](https://github.com/reactjs/react-router)


#### Opal under the covers

Hyperstack Components are a DSL wrapper of React which uses Opal to compile Ruby code to ES5 native JavaScript. If you have not used Opal before then you should at a minimum read the excellent guides as they will teach you enough Opal to get you started with Hyperstack.

+ [Opal](http://opalrb.org/)
+ [Opal Guides](http://opalrb.org/docs/guides/v0.9.2/index.html)
+ [To see the full power of Opal in action watch this video](https://www.youtube.com/watch?v=vhIrrlcWphU)
