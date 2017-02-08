## HyperStore

+ `HyperStore` can be mixed to to any class to turn it into a Flux Store
+ You can also create Stores by subclassing `HyperStore::Base`
+ Stores are built out of *reactive state variables.*  
+ Components that *read* a Stores state will be automatically updated when the state changes.  
+ All of your *shared* reactive state should be Stores - The Store is the Truth
+ Stores can *receive* *dispatches* from *Operations*

Here is a simple shopping cart Store that receives Add, Remove and Empty Operations:

```ruby
class Cart < HyperStore::Base
  # First we will define the two Operations.
  # Because these are closely associated with the Cart
  # we will name space them inside the cart.
  class Add < HyperOperation
    param :item
    param :qty, type: Integer, min: 1
  end
  class Remove < HyperOperation
    param :item
    param :qty, type: Integer, nils: true, min: 1
  end
  class Empty < HyperOperation
  end

  # The cart's state is represented as a hash, items are the keys, qty is the value
  # initialize the hash by receiving the system HyperLoop::Boot or Empty dispatches

  receives HyperLoop::Boot, Empty do
    mutate.items(Hash.new { |h, k| h[k] = 0 })
  end

  # The stores getter (or reader) method

  def self.items
    state.items
  end

  def self.empty?
    state.items.empty?
  end

  receives Add do
    # notice we use mutate.items since we are modifying the hash
    mutate.items[params.item] += params.qty
  end

  receives Remove do
    mutate.items[params.item] -= params.qty
    # remove any items with zero qty from the cart
    mutate.items.delete(params.item) if state.items[params.item] < 1
  end
end
```

This example demonstrates the two ingredients of a Store:  

+ Receiving Operation Dispatches and
+ Reading, and Mutating *states*.

These are explained in detail below.

## Receiving Operation Dispatches

Stores can receive Operation dispatches using the receive method.

The `receive` method takes an list of Operations, and either a symbol (indicating a class method to call), a proc, or a block.

When the dispatch is received the method, proc, or block will be run within the context of the Store's class (not an instance.)  In addition the `params` method from the Operation will be available to access the Operations parameters.

The *Flux* paradigm promotes only mutating state inside of receivers.

Hyperloop is less opinionated.  You may also add mutator methods to your class.  Our recommendation is that you append an exclamation (!) to methods that mutate state.

Note that it is reasonable to have several receivers for the same Operation.  This allows subclassing, mixins, and separation of concerns.

Note also that the Ruby scoping rules make it very reasonable to define the Operations to be received by a Store inside the Store's scope.  This does not change the semantics of either the Store or the Operation, but simply keeps the name space organized.

## Reading and Mutating States

A Store will have one or more *Reactive State Variables* or *State* for short.  States are read using the `state` method, and are changed using the `mutate` method.

`state.items` reads the current value of the state named `items`.  Hyperloop tracks all reads of state, and mutating those states will trigger a re-render of any Components depending on the current value.

`mutate.items` returns the current value of the state named `items`, but also tells Hyperloop that the value is changing, and that any Components depending on the current value will have to be re-rendered.

The one thing you must remember to do is use `mutate` if you intend to update the internal value of a state.  For example if the state contains a hash, and you are updating the Hash's internal value you would use `mutate` otherwise the change will go unrecorded.  

#### Initializing States

To assign a new value to a state use the `mutate` method and pass a parameter to the state:

```ruby
mutate.items(Hash.new { |h, k| h[k] = 0 })
```

#### Reading States

To read the current value of a state use the `state` method:

```ruby
state.items # returns current value of items
```

Typically a store will have quite a few reader (aka getter) methods that hide the details of the state, allowing the Store's implementation to change, without effecting the interface.

#### Mutating States

Often states hold data structures like arrays, hashes, sets, or other Ruby classes, which may be *mutated*.  For example when you push a new value onto an array you will mutate it.  The *value* of the array does not change, but its *contents* does.  If you are accessing a state with the intent to change its content then use the `mutate` method:

```ruby
mutate.items[item] = value
```

#### Explicitly Declaring States

States like instance variables are created when they are first referenced.  

As a convenience you may also explicitly declare states.  This reduces code noise, and improves readability.

```ruby
class Cart < HyperStore::Base
  state items: Hash.new { |h, k| h[k] = 0 }, scope: :class, reader: true
end
```

This *declares* the `items` state as a class state variable, will initialize it with the hash on `Hyperloop::Boot`, and provides a reader method.
That is 6 lines of code for the price of 1, plus now the intention of `items` is clearly defined.

The `state` declaration has the following flavors, depending on how the state is to be initialized:

```ruby
  state :items, ... other options ... # items will be initialized to nil
  state items: [1, 2, 3], ... other options ... # items will be initialized to the array [1, 2, 3]
  state :items, ... other options ... do
    ... compute initial value ...
    ... context will be either the class an ...
    ... instance depending on the scope ...
  end
```

other options to the `state` declaration are:
+ `scope:` either `:class`, `:instance`, `:shared`.  Details below!
+ `reader:` either `true`, or a symbol used to declare a reader (getter) method.  
+ `initializer:` either a proc or a symbol (indicating a method), to be used to initialize the state.

The value of the `scope` option determines where the state resides.  
+ A class state has one instance per class and is directly accessible in class methods, and indirectly in instances using `self.class.state`.
+ An instance state has a different copy in each instance of the class, and is not accessible by class methods.
+ A shared state is like a class state, but is also directly accessible in instances.

The default value for `scope:` depends on where the state is declared:

```ruby
  state :items # declares an instance state variable, each instance gets its own state
  class << self
    state :items # declares a class instance state variable
  end
```

In the above example there is one class instance state named `items` and an addition *different* state variable also called
items for each instance.

The `shared` option just makes it easier to access a class state from instances.

```ruby
class MyStore < HyperStore::Base
  state :shared_state, scope: :shared
  state :class_state, scope: :class
  state :instance_state # scope: :instance is default here
  def instance_method
    # shared state makes class states easy to access
    state.shared_state
    # without shared state class_state is still accessible
    # with more typing
    self.class.class_state
    # each instance gets its own copy of instance states
    state.instance_state
    # attempt to access a declared state variable out of context
    # results in an error!
    state.class_state # exception!
  end
  def self.class_method
    # this is the same state as was referenced in instance_method
    state.shared_state
    # and so is this
    state.class_state
    # and this will raise an exception
    state.instance_state
  end
```

Class state variables are initialized by an implicit `Hyperloop::Boot` receiver.  If an initial value is directly provided (not via a proc, method or block) then the value will be `dup`ed when the second and following Boot dispatches are received.  The proc, method or block initializers will run in the context of the class, and the state variable will be available.  For example:

```ruby
state :boot_counter, scope: :shared do
  (state.boot_counter || 0)+1
end

# more practically perhaps:

state :my_state, scope: :shared do
  state.my_state || [] # don't re-initialize me on reboots
end
```

Instance variables are initialized when instances of the Store are created.  Each initialization will `dup` the initial value unless supplied by a proc, method or block.

This initialization behavior will work in most cases but for more control simply leave off any initializer, and write your own.

**Note for class states there is a subtle difference between saying:**
```ruby
state my_state: nil, scope: :shared # or :class
# and
state :my_state, scope: :shared # or :class

```

In the first case `my_state` will be re-initialized to nil on every boot, in the second case it will not.



#### The `state_reader` and `private_state` methods

These are convenience methods that reduce code noise:

The `state_reader` method will
+ initialize a state automatically and
+ create a *getter* method

```ruby
state_reader items: Hash.new { |h, k| h[k] = 0 }, scope: :class
# same as
receives HyperLoop::Boot do
  mutate.items(Hash.new { |h, k| h[k] = 0 } )
end
def self.items
  state.items
end
# 6 lines for the price of 1!
```

The `:scope` option indicates whether the state exists once for the class, or for each instance.  More on instance states in a bit.

You may leave off the initializer by just giving the name of the state, and it will be initialized to nil
```ruby
state_reader :ready? # initialized to nil
```

You may use the `as:` option to give a different name to the reader method than the state.  This can help make the code more readable.  For example:
```ruby
class Todos < HyperStore::Base
  state_reader todos: [], scope: :class, as: :all
  # now we can internally refer to our state as todos, while
  # externally it can be called Todos.all
end
```

The `private_state` method works the same but does not create the reader method.  Its useful for initializing states, and makes the code more readable by declaring upfront what states you are using.

### Instances and Classes

Stores are often singleton classes.  In an application there is one 'cart' for example.

However sometimes you will want to create a normal Ruby class that acts as a Store.  If a state is read or mutated in an instance method, then you will be referring to that instance's copy of the state.  When you use `state_reader` and `private_state` you can use the `scope: :instance` option.  The only caveat is that if you use `state_reader` or `private_state` with `scope: :class`, then that variable will be directly accessible to the instances as well.  In other words you can't have the same state declared at the class and instance level.

On the other hand you can also use the `state_reader` and `private_state` method within a classes *I DONT KNOW WHAT TO CALL THIS*.  In this case the default scope is class instead of instance.

```ruby
class Foo < HyperStore::Base
  class << self
    private_state :bar
    # bar by default is a class state variablle
  end
end
```

### The `HyperStore` Mixin

You can also include `HyperStore` in any class and then use all the methods described above.  Useful when you want to add HyperStore capabilities to another class.

### States and Promises

If you assign a promise to a state Hyperloop is clever, and will not mutate the state *until the promise resolves*.  Combining this with instance Stores gives a powerful way to encapsulate system behavior.
