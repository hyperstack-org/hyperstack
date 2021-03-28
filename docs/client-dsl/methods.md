### Class Methods

The following methods are used to define the interface and behavior of instances of the component
class.  You may also use any other Ruby constructs such as method definition as
you would in any Ruby class.

**Interface Definition**
These methods define the signature of the component's params.
+ `param(*args)` - specifies params and creates accessor methods
+ `fires(name, alias: internal_name)` - specifies an event call-back
+ `others(name)` accessor method that collects all params not otherwise specified
+ `other, other_params, opts, collect_other_params_as` aliases for `others`

**Lifecycle Methods**
These methods define the behavior of the component through its lifecycle.  All
components must have a `render` callback. If no signature is specified the method will
take a list of method names, and/or a callback block.  Except for render, you may
define multiple handlers for each callback.
+ `render(opt_comp_name, opt_params, &block)`
+ `before_mount`
+ `after_mount`
+ `before_new_params`
+ `before_update`
+ `after_update`
+ `before_render` before all renders
+ `after_render` after all renders
+ `rescues(*klasses_to_rescue, &block)`

**State Management**
Each component instance has internal state represented by the contents of instance variables:
changes to the state is signaled using the `mutate` method.  The following methods
define additional instance methods that access state with built-in calls to the mutate method.
+ `mutator` defines an *instance* method with a built-in mutate.
+ `state_reader` creates an *instance* state read only accessor method.
+ `state_writer` creates an *instance* state write only accessor method.
+ `state_accessor` creates *instance* reader and writer methods.

**Other Class Level Methods**
+ `mounted_components` - returns an array of all currently mounted components of this class and subclasses
+ `force_update!` forces all components in this class and its subclasses to update
+ `create_element(*params, &children)` - create an element from this class
+ `insert_element(*params, &children)` - create and insert an element into the rendering buffer

### Instance Methods

**Inserting Elements**

All HTML and SVG tags, and all other Components visible to this instance can be inserted into the
rendering buffer by using the tag or component class name followed either by parens and/or a block:

`DIV(...)` or `DIV { ... }` or `DIV(...) { ... }`

Note that this is just short for `DIV.insert_element(...) { ... }`

Parameters can be passed as a combination of strings and symbols followed by any number of hashes.

Any symbols or strings will be treated as a hash key with a value of true and will be merged with the rest of the
hashes:

```Ruby
MyComp(:foo, 'bar-ski', {class: :joe, id: 12}, data: 123)
# is the same as
MyComp(foo: true, 'bar-ski' => true, class: :joe, id: 12, data: 123)
```

**Attaching Callback Handlers**

Component params that expect `Procs` can passed as normal or using the `.on` method:

```Ruby
BUTTON { 'click me' }.on(:click) { alert('you clicked?') }
# is the same as
BUTTON(on_click: -> { alert('you clicked') }) { 'click me' }
```

**State Management**

When an event occurs it will probably change state.  The mutate method is used to signal the
state change.

+ `mutate` signals that this instance's state has been mutated
+ `toggle(:foo)` is short for `mutate @foo = !@foo`

**Other Methods**

+ `children` enumerates the children of this component
+ `alert(message)` js alert
+ `after(time, &block)` run block after `time` seconds
+ `every(time, &block)` run block every `time` seconds
+ `pluralize(count, singular, plural = nil)` equivalent to Rails pluralize helper
+ `dom_node` returns the DOM node of this component
+ `jq_node` short for `jQ[dom_node]`
+ `force_update!` Almost always components should render due to a state change or when receiving new params.
+ `~` Removes the instance from the current rendering buffer.  This is done automatically in most cases when needed.
