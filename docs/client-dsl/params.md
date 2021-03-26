The `param` class method gives _read-only_ access to each of the params passed to the component. Params are accessed as instance methods of the component.

>In React params are called `props`, but Hyperstack uses the more common Rails term `param`.

Within a component class the `param` method is used to define the parameter signature of the component. You can think of params as the values that would normally be sent to the instance's `initialize` method, but with the difference that a component will get new parameters during its lifecycle.

The param declaration has several options providing a default value, expected type, and an internal alias name.

Examples:

```ruby
param :foo # declares that we must be provided with a parameter foo when the component is instantiated or re-rerendered.
param :foo => "some default"        # declares that foo is optional, and if not present the value "some default" will be used.
param foo: "some default"           # same as above using ruby 1.9 JSON style syntax
param :foo, default: "some default" # same as above but uses explicit default key
param :foo, type: String            # foo is required and must be of type String
param :foo, type: [String]          # foo is required and must be an array of Strings
param foo: [], type: [String]       # foo must be an array of strings, and has a default value of the empty array.
param :foo, alias: :something       # the alias name will be used for the param (instead of foo)
```

#### Accessing param values

Params are accessible in the component as instance methods.  For example:

```ruby
class Hello < HyperComponent
  # visitor has a default value (so its not required)
  # and must be of type (i.e. instance of) String
  param visitor: "World", type: String

  render do
    "Hello #{visitor}"
  end
end
```

### Param Validation

As your app grows it's helpful to ensure that your components are used correctly.You do this by specifying the expected ruby class of your parameters. When an invalid value is provided for a param, a warning will be shown in the JavaScript console. Note that for performance reasons type checking is only done in development mode. Here is an example showing typical type specifications:

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

Note that if the param has a type but can also be nil, add `allow_nil: true` to the specification.

### Default Param Values

You can define default values for your `params`:

```ruby
class ManyParams < HyperComponent
  param :an_optional_param, default: "hello", type: String, allow_nil: true
```

If no value is provided for `:an_optional_param` it will be given the value `"hello"`, it may also be given the value `nil`.

Defaults can be provided by the `default` key or using the syntax `param foo: 12` which would default `foo` to 12.

### Component Instances as Params

You can pass an instance of a component as a `param` and then render it in the receiving component.

```ruby
class Reveal < HyperComponent
  param :content
  render do
    BUTTON { "#{@show ? 'hide' : 'show'} me" }
    .on(:click) { mutate @show = !@show }
    content.render if @show
  end
end
class App < HyperComponent
  render do
    Reveal(content: DIV { 'I came from the App' })
  end
end
```

`render` is used to render the child components. **[For details ...](component-details.md#rendering-children)**

> Notice that this is just a way to pass a child to a component but instead of sending it to the "block" with other children you are passing it as a single named child.

### Other Params

A common type of component is one that extends a basic HTML element in a simple way. Often you'll want to copy any HTML attributes passed to your component to the underlying HTML element.

To do this use the `others` method which will gather all the params you did not declare into a hash. Then you can pass this hash on to the child component

```ruby
class CheckLink < HyperComponent
  others :attributes
  render do
    # we just pass along any incoming attributes
    A(attributes) { '√ '.span; children.each &:render }
  end
end

  # elsewhere
  CheckLink(href: "/checked.html")
```

Note: `others` builds a hash, so you can merge other data in or even delete elements out as needed.

### Aliasing Param Names

Sometimes we can make our component code more readable by using a different param name inside the component than the owner component will use.

```ruby
class Hello < HyperComponent
  param :name
  param include_time: true, alias: :time?
  render { SPAN { "Hello #{name}#{'the time is '+Time.now if time?}" } }
end
```

This way we can keep the interface very clear, but keep our component code short and sweet.

### Updating Params

Each time a component is rendered any of the components it owns may be re-rendered as well **but only if any of the params will change in value.**
If none of the params change in value, then the owned-by component will not be rerendered as no parameters have changed.

Hyperstack determines if a param has changed through a simple Ruby equality check.  If `old_params == new_params` then no update is needed.

For strings, numbers and other scalar values equality is straight forward.  Two hashes are equal if they each contain the same number of keys
and if each key-value pair is equal to the corresponding elements in the other hash.  Two arrays are equal if they contain the same number of
elements and if each element is equal to the corresponding element in the other array.

For other objects unless the object defines its own equality method the objects are equal only if they are the same instance.

Also keep in mind that if you pass an array or hash (or any other non-scalar object) you are passing a reference to the object **not a copy**.

Lets look at a simple (but contrived) example and see how this all plays out:

```RUBY
class App < HyperComponent
  render do
    DIV do
      BUTTON { "update" }.on(:click) { force_update! }
      new_hash = {foo: {bar: [12, 13]}}
      Comp2(param: new_hash)
    end
  end
end

class Comp2 < HyperComponent
  param :param
  render do
    DIV { param }
  end
end
```

Even though we have not gotten to event handlers yet, you can see what is going on:  When we click the update button we call `force_update!`
which will force the `App` component to rerender.
> By the way `force_update!` is almost never used, but we are using it here
just to make the example clear.)

Will `Comp2` rerender?  No - because even though we are creating a new hash, the old hash and new hash are equal in value.

What if we change the hash to be `{foo: {bar: [12, Time.now]}}`.  Will `Comp2` re-render now?  Yes because the old and new hashes are no longer equal.

What if we changed `App` like this:

```RUBY
class App < HyperComponent
  # initialize an instance variable before rendering App
  before_mount { @hash = {foo: {bar: [12, 13]}} }
  render do
    DIV do
      BUTTON { "update" }.on(:click) do
        @hash[:foo][:bar][2] = Time.now
        force_update!
      end
      Comp2(param: @hash)
    end
  end
end
```

Will `Comp2` still update?  No. `Comp2` received the value of `@hash` on the first render, and so `Comp2` is rendering the same copy of `@hash` that `App` is changing.
So when we compare *old* verses *new* we are comparing the same object, so the values are equal even though the contents of the hash has changed.

### Conclusion

That does not seem like a very happy ending, but the case we used was not very realistic.  If you stick to passing simple scalars, or hashes and arrays
whose values don't change after they have been passed, things will work fine.  And for situations where you do need to store and
manipulate complex data, you can use the **[the Hyperstack::Observable module](/hyper-state/README.md)** to build safe classes that don't
have the problems seen above.
