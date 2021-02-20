# HyperSpec Methods and Features

### Expectation Helpers

These can be used any where within your specs:

+ [`on_client`](#the-on_client-method) - executes code on the client
+ [`isomorphic`](#the-isomorphic-method) - executes code on the client *and* the server
+ [`mount`](#mounting-components) - mounts a hyperstack component in an empty window
+ [`before_mount`](#before_mount) - specifies a block of code to be executed before the first call to `mount`, `isomorphic` or `on_client`
+ [`insert_html`](#insert_html) - insert some html into a page
+ [`client_options`](#client-initialization-options) - allows options to be specified globally
+ [`run_on_client`](#run_on_client) - same as `on_client` but no value is returned
+ [`reload_page`](#reload_page) - resets the page environment
+ [`add_class`](#add_class) - adds a CSS class
+ [`size_window`](#size_window) - specifies how big the client window should be
+ [`attributes_on_client`](#attributes_on_client) - returns any ActiveModel attributes loaded on the client

These methods are used after mounting a component to retrieve
events sent outwards from the component:

+ [`callback_history_for`](#retrieving-event-data-from-the-mounted-component)
+ [`last_callback_for`](#retrieving-event-data-from-the-mounted-component)
+ [`clear_callback_history_for`](#retrieving-event-data-from-the-mounted-component)
+ [`event_history_for`](#retrieving-event-data-from-the-mounted-component)
+ [`last_event_for`](#retrieving-event-data-from-the-mounted-component)
+ [`clear_event_history_for`](#retrieving-event-data-from-the-mounted-component)

### Expectation Targets

These can be used within expectations replacing the `to` and `not_to` methods.  The expectation expression must be inclosed in a block.

+ [`on_client_to`](#client-expectation-targets), [`to_on_client_not`](#client-expectation-targets) - the expression will be evaluated on the client, and matched on the server.

These methods have the following aliases to make your specs more readable:
+ [`to_on_client`](#client-expectation-targets)
+ [`on_client_to_not`](#client-expectation-targets)
+ [`on_client_not_to`](#client-expectation-targets)
+ [`to_not_on_client`](#client-expectation-targets)
+ [`not_to_on_client`](#client-expectation-targets)
+ [`to_then`](#client-expectation-targets)
+ [`then_to_not`](#client-expectation-targets)
+ [`then_not_to`](#client-expectation-targets)
+ [`to_not_then`](#client-expectation-targets)
+ [`not_to_then`](#client-expectation-targets)

in addition
+ [`with`](#client-expectation-targets) - can be chained with the above methods to pass data to initialize local variables on the client

### Other Debugging Aids

The following methods are used primarly at a debug break point, most require you use binding.pry as your debugger:

+ [`to_js`](#to_js) - returns the ruby code compiled to JS.
+ [`c?`](#c?) - alias for `on_client`.  
+ [`ppr`](#ppr) - print the results of the ruby expression on the client console.
+ [`debugger`](#debugger) - Sets a debug breakpoint on code running on the client.
+ [`open_in_chrome`](#open_in_chrome) - Opens a chrome browser that will load the current state.  
+ [`pause`](#pause) - Halts execution on the server without blocking I/O.

### Available Webdrivers

HyperSpec comes integrated with Chrome and Chrome headless webdrivers.  The default configuration will run using Chrome headless.  To see what is going on set the `DRIVER` environment variable to `chrome`
```bash
DRIVER=chrome bundle exec rspec
```

### Timecop Integration

You can use the [`timecop` gem](https://github.com/travisjeffery/timecop) to control the flow of time within your specs.  Hyperspec will coordinate things with the client so the time on the client is kept in sync with the time on the server.  So for example if you use Timecop to advance time 1 day on the server, time on the browser will also advance by one day.  

See the [Client Initialization Options](#client-initialization-options) section for how to control the client time zone, and clock resolution.

### The `no_reset` flag

By default the client environment will be reinitialized at the beginning of every spec.  If this is not needed you can speed things up by adding the `no_reset` flag to a block of specs.

# Details

### The `on_client` method

The on_client method takes a block.  The ruby code inside the block will be executed on the client, and the result will be returned.

```ruby
  it 'will print a message on the client' do
    on_client do
      puts 'hey I am running here on the client!'
    end
  end
```

If the block returns a promise Hyperspec will wait for the promise to be resolved before returning.  For example:

```ruby
  it 'waits for a promise' do
    start_time = Time.now
    result = on_client do
      promise = Promise.new
      after(10.seconds) { promise.resolve('done!') }
      promise
    end
    expect(result).to eq('done!')
    expect(Time.now-start_time).to be >= 10.seconds
  end
```    
> HyperSpec will do its best to reconstruct the result back on the server in some sensible way.  Occasionally it just doesn't work, in which case you can end the block with a `nil` or some other simple expression, or use the `run_on_client` method, which does not return the result.

### Accessing variables on the client

It is often useful to pass variables from the spec to the client.  Hyperspec will copy all your local variables, memoized variables, and instance variables known at the time the `on_client` block is compiled to the client.</br>
```ruby
  let!(memoized) { 'a memoized variable' }
  it 'will pass variables to the client' do
    local = 'a local variable'
    @instance = 'an instance variable'
    result = on_client { [memoized, local, @instance] }
    expect(result).to eq [memoized, local, @instance]
  end  
```
> Note that memoized variables are not initialized until first
accessed, so you probably want to use the let! method unless you
are sure you are accessing the memoized value before sending it to the client.

The value of instance variables initialized on the client are preserved
across blocks executed on the client.  For example:
```ruby
  it 'remembers instance variables' do
    on_client { @total = 0 }
    10.times do |i|
      # note how we are passing i in
      on_client { @total += i }
    end
    result = on_client { @total }
    expect(result).to eq(10 * 11 / 2)
  end
```

> Be especially careful of this when using the [`no_reset`](#the-no_reset-flag) as instance variables will retain their values between each spec in this mode.

#### White and Black Listing Variables

By default all local variables, memoized variables, and instance variables in scope in the spec will be copied to the client.  This can be controlled through the `include_vars` and `exclude_vars` [client options](#client-initialization-options).

`include_vars` can be set to  
+ an array of symbols: only those vars will be copied,
+ a single symbol: only that var will be copied,
+ any other truthy value: all vars will be copied (the default)
+ or nil, false, or an empty array: no vars will be copied.

`exclude_vars` can be set to
+ an array of symbols - those vars will **not** be copied,
+ a single symbol - only that var will be excluded,
+ any other truthy value - no vars will be copied,
+ or nil, false, or an empty array - all vars will be copied (the default).

Examples:

```Ruby
  # don't copy vars at all.
  client_option exclude_vars: true
  # only copy var1 and the instance var @var2
  client_option include_vars: [:var1, :@var2]
  # only exclude foo_var
  client_option exclude_vars: :foo_var
```

Note that the exclude_vars list will take precedence over the include_vars list.

The exclude/include lists can be overridden on an individual call to on_client by providing a hash of names and values to on_client:

```ruby
  result = on_client(var: 12) { var * var }
  expect(result).to eq(144)
```

You can do the same thing on expectations using the `with` method - See [Client Expectation Targets](#client-expectation-targets).


### The `isomorphic` method

The `isomorphic` method works the same as `on_client` but in addition it also executes the same block on the server. It is especially useful when doing some testing of
ActiveRecord models, where you might want to modify the behavior of the model on server and the client.

```ruby
  it 'can run code the same everywhere!' do
    isomorphic do
      def factorial(x)
        x.zero? ? 1 : x * factorial(x - 1)
      end
    end

    on_the_client = on_client { factorial(7) }
    on_the_server = factorial(7)
    expect(on_the_client).to eq(on_the_server)
  end
```

### Client Initialization Options

The first time a spec runs code on the client, it has to initialize a browser context.  You can use the `client_options` (aka `client_option`) method to specify the following options when the page is loaded.

+ `time_zone` - browsers always run in the local time zone, if you want to force the browser to act as if its in a different zone, you can use the time_zone option, and provide any valid zone that the rails `in_time_zone` method will accept.<br/>
Example: `client_option time_zone: 'Hawaii'`
+ `clock_resolution`:  Indicates the resolution that the simulated clock will run at on the client, when using the TimeCop gem.  The default value is 20 (milliseconds).
+ `include_vars`: white list of all vars to be copied to the client.  See [Accessing Variables on the Client](#accessing-variables-on-the-client) for details.
+ `exclude_vars`: black list of all vars not to be copied to the client.  See [Accessing Variables on the Client](#accessing-variables-on-the-client) for details.
+ `render_on`: `:client_only` (default), `:server_only`, or `:both`  
Hyperstack components can be prerendered on the server.  The `render_on` option controls this feature.  For example `server_only` is useful to insure components are properly prerendered.  *See the `mount` method [below](#mounting-components) for more details on rendering components*
+ `no_wait`: After the page is loaded the system will by default wait until all javascript requests to the server complete before proceeding. Specifying `no_wait: true` will skip this.
+ `javascript`: The javascript asset to load when mounting the component.  By default it will be `application` (.js is assumed).  Note that the standard Hyperstack configuration will compile all the client side Ruby assets as well as javascript packages into the `application.js` file, so the default will work fine.
+ `style_sheet`: The style sheet asset to load when mounting the component.  By default it will be `application` (.css is assumed).
+ `controller` - **(expert zone!)** specify a controller that will be used to mount the
component.  By default hyper-spec will build a controller and route to handle the request from the client to mount the component.

Any other options not listed above will be passed along to the Rail's controller `render` method.  So for example you could specify some other specific layout using `client_option layout: 'special_layout'`

Note that this method can be used in the `before(:each)` block of a spec context to provide options for all the specs in the block.

### Mounting Components

The `mount` method is used to render a component on a page:

```ruby
  it 'can display a component for me' do
    mount 'SayHello', name: 'Lannar' do
      class SayHello < HyperComponent
        param :name
        render(DIV) do
          "Hello #{name}!"
        end
      end
    end

    expect(page).to have_content('Hello Lannar')
  end
```

The `mount` method has a few options.  In it's simplest form you specify just the name of the component that is already defined in your hyperstack code and it will be mounted.

You can add parameters that will be passed to the component as in the above example.  As the above example also shows you can also define code within the block. This is just shorthand for defining the code before hand using `on_client`.  The code does not have to be the component being mounted, but might be just some logic to help with the test.

In addition `mount` can take any of the options provided to `client_options` (see above.)   To provide these options, you must provide a (possibly) empty params hash.  For example:  
```ruby
mount 'MyComponent', {... params ... }, {... opts ... }
```

### Retrieving Event Data From the Mounted Component

Components *receive* parameters, and may send callbacks and events back out.  To test if a component has sent the appropriate data you can use the following methods:

+ `callback_history_for`
+ `last_callback_for`
+ `clear_callback_history_for`
+ `event_history_for`
+ `last_event_for`
+ `clear_event_history_for`

```ruby
  it 'can check on a clients events and callbacks' do
    mount 'BigTalker' do
      class BigTalker < HyperComponent
        fires :i_was_clicked
        param :call_me_back, type: Proc

        before_mount { @click_counter = 0 }

        render(DIV) do
          BUTTON { 'click me' }.on(:click) do
            @click_counter += 1
            i_was_clicked!
            call_me_back.call(@click_counter)
          end
        end
      end
    end
    3.times do
      find('button').click
    end
    # the history is an array, one element for each item in the history
    expect(event_history_for(:i_was_clicked).length).to eq(3)
    # each item in the array is itself an array of the arguments
    expect(last_call_back_for(:call_me_back)).to eq([3])
    # clearing the history resets the array to empty
    clear_event_history_for(:i_was_clicked)
    expect(event_history_for(:i_was_clicked).length).to eq(0)
  end
```

> Note that you must declare the params as type `Proc`, or use
the `fires` method to declare an event for the history mechanism to work.

### Other Helpers

#### `before_mount`

Specifies a block of code to be executed before the first call to `mount`, `isomorphic` or `on_client`.  This is primarly useful to add to an rspec `before(:each)` block containing common client code needed by all the specs in the context.  

> Unlike `mount`, `isomorphic` and `on_client`, `before_mount` does not load the client page, but will wait for the first of the other methods to be called.

#### `add_class`

Adds a CSS class.  The first parameter is the name of the class, and the second is a hash of styles, represented in the React [style format.](https://reactjs.org/docs/dom-elements.html#style)

Example: `add_class :some_class, borderStyle: :solid` adds a class with style `border-style: 'solid'`  

#### `run_on_client`

same as `on_client` but no value is returned.  Useful when the return value may be too complex to marshall and unmarshall using JSON.

#### `reload_page`

Shorthand for `mount` with no parameters.   Useful if you need to reset the client within a spec.

#### `size_window`

Indicates the size of the browser window.  The values can be given either symbolically or as two numbers (width and height).  Predefined sizes are:

+ `:small`: 480 x 320
+ `:mobile` 640 x 480
+ `:tablet` 960 x 64,
+ `:large` 1920 x 6000
+ `:default` 1024 x 768

All of the above can be modified by providing the `:portrait` option as the first or second parameter.

So for example the following are all equivalent:

+ `size_window(:small, :portrait)`
+ `size_window(:portrait, :small)`
+ `size_window(320, 480)`

#### `attributes_on_client`

returns any `ActiveModel` attributes loaded on the client.  HyperModel will normally begin a load cycle as soon as you access the attribute on the client.  However it is sometimes useful to see what attributes have already been loaded.

#### `insert_html`

takes a string and inserts it into test page when it is mounted.  Useful for testing code that is not dependent on Hyper Components.
For example an Opal library that adds some jQuery extensions.

### Client Expectation Targets

These can be used within expectations replacing the `to` and `not_to` methods.  The expectation expression must be inclosed in a block.

For example:

```ruby
it 'has built-in expectation targets' do
  expect { RUBY_ENGINE }.on_client_to eq('opal')
end
```

The above expectation is short for saying:

```ruby
  result = on_client { RUBY_ENGINE }
  expect(result).to eq('opal')
```

These methods have the following aliases to make your specs more readable:
+ `to_on_client`
+ `on_client_to_not`
+ `on_client_not_to`
+ `to_not_on_client`
+ `not_to_on_client`
+ `to_then`
+ `then_to_not`
+ `then_not_to`
+ `to_not_then`
+ `not_to_then`

The `then` variants are useful to note that the spec involves a promise, but it does no explicit checking that the result comes from a promise.

In addition the `with` method can be chained with the above methods to pass data to initialize local variables on the client:

```ruby
  it 'can pass values to the client using the with method' do
    expect { foo * foo }.with(foo: 12).to_on_client eq(144)
  end
```

By default HyperSpec will copy all local variables, memoized variables, and instance variables defined in a spec to the client.  The specific variables can also be white listed and black listed.  The `with` method overrides any white or black listed values.  So for example if you prefer to use the more explicit `with` method to pass values to the client, you can add `client_option exclude_vars: true` in a `before(:all)` block in your spec helper.  See [Accessing Variables on the Client](#accessing-variables-on-the-client) for details.

### Useful Debug Methods

These methods are primarily designed to help debug code and specs.

#### `c?`

Shorthand for `on_console`, useful for entering expressions in pry console, to investigate the state of the client.

```ruby
pry:> c? { puts 'hello on the console' } # prints hello on the client
-> nil
```

#### `to_js`

Takes a block like `on_client` but rather than running the code on the client, simply returns the resulting code.  This is useful for debugging obscure problems when the Opal compiler or some feature of
Hyperspec is suspected as the issue.

#### `ppr`

Takes a block like `on_client` and prints the result on the client console using JS console.log.  Equivalent to doing

```ruby
  on_client do  
    begin
      ...
    end.tap { |r| `console.log(r)` }
  end
```

This is useful when the result cannot be usefully returned to the server,
or when the result of interest is better looked at as the raw
javascript object.

#### `debugger`

This psuedo method can be inserted into any code executed on the client.  It will cause the code to stop, and enter a *javascript* read-eval loop, within the debug console.

Unfortunately ATM we do not have the technology to enter a *Ruby* read-eval loop at an arbitrary point on the client.

> Note: due to a bug in the Opal compiler your code should not have `debugger` as the last expression in a method or a block.  In this situation add any expression (such as nil) after the debugger statement.  
```ruby
def foo
  ... some code ...
  debugger  # this will fail with a compiler syntax error
end
```

#### `open_in_chrome`
By default specs are run with headless chrome, so there is no visible browser window.  The `open_in_chrome` method will open a browser window, and load it with the current state.

You can also run specs in a visible chrome window by setting the `DRIVER` environment variable to `CHROME`

#### `pause`
The method is typically not needed assuming you are using a multithreaded server like Puma.  If for whatever reason the pry debug session is not multithreaded, *and* you want to try some kind of experiment on the javascript console, *and* those experiments make requests to the server, you may not get a response, because all threads are in use.  

You can resolve this by using the `pause` method in the debug session which will put the server debug session into a non-blocking loop.  You can then experiment in the JS console, and when done release the pause by executing `go()` in the *javascript* debug console.
