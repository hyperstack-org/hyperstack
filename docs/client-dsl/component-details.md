## Children, Keys, and Fragments

### Children

Components often have child components.  If you consider HTML tags like `DIV`, `UL`, and `TABLE`
you will see you are already familiar with this concept:

```ruby
DIV(id: 1) do
  SPAN(class: :span_1)  { 'hi' }
  SPAN(class: :span_2) { 'there' }
end
```
Here we have a `DIV` that receives one param, an id equal to 1 *and* has two child *elements* - the two spans.

The `SPAN`s each have one param (its class) and has one child *element* - a string to render.

Hopefully the DSL is intuitive to read, and you can see that this will generate the following HTML:
```HTML
<div id=1><span class='first_span'>hi</span><span class='second_span'>there</span></div>
```

### Dynamic Children

Children do not have to be statically generated.  Let's sort a string of text
into individual word counts and display it in a list:

```ruby
# assume text is a string of text
UL do
  word_count(text).each_with_index do |word, count|
    LI { "#{count} - #{word}" }
  end
end
```
Here we don't determine the actual number or contents of the `LI` children until runtime.

>**[The `word_count` method...](notes#word-count-method)**

>Dynamically generating components creates a new concept called ownership.  **[More here...](notes#ownership)**

### Keys

In the above example what would happen if the contents of `text` were dynamically changing? For
example if it was associated with a text box that user was typing into, and we updated `text`
whenever a word was entered.

In this case as the user typed new words, the `word_count` would be updated and the list would change.
However actually only the contents of one of list items (`LI` blocks) would actually change, and
perhaps the sort order.  We don't need to redraw the whole list, just the one list item that changed,
and then perhaps shuffle two of the items.  This is going to be much faster than redrawing the whole
list.

Like React, Hyperstack provides a special key param that you can identify child elements so that the
rendering engine will know that while the content and order may change on some children, it can easily
identify the ones that are the same:

```ruby
    LI(key: word) { "#{count} - #{word}"}
```

You don't have to stress out too much about keys, its easy to add them later.  Just keep the concept in
mind when you are generating long lists, tables, and divs with many children.

> **[More on how Hyperstack generates keys...](notes#generating-keys)**



### Child Reconciliation

**Reconciliation is the process by which the underlying React engine updates the DOM with each new render pass.** In general, children are reconciled according to the order in which they are rendered. For example, suppose we have the following render method displaying a list of items. On each pass the items will be regenerated and then merged into the DOM by React.

```ruby
param :items
render do
  items.each do |item|
    P { item[:text] }
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

### Rendering Children

A component's `children` method returns an enumerable that is used to access the *unrendered* children of a component.  The children can then be rendered
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
    # without the keys you would get a warning
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

If you are sure that the order and number of elements will not change over time you may wrap the items in the `FRAGMENT` pseudo component:

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
