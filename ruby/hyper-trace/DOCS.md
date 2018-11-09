# HyperTrace

Method tracing and conditional break points for [Opal](http://opalrb.org/) and [Hyperstack](http://hyperstack.org) debug.

Typically you are going to use this in Capybara or Opal-RSpec examples that you are debugging.

HyperTrace adds a `hypertrace` method to all classes that you will use to switch on tracing and break points.

For example:

```ruby
SomeClass.hypertrace instrument: :all
```

Will instrument all methods in `SomeClass` and you will get a trace like this:

<img width="952" alt="screen shot 2016-10-22 at 11 08 56 pm" src="https://cloud.githubusercontent.com/assets/63146/19624133/48098fce-98b6-11e6-9198-cc5eae836ccf.png">

The trace log uses the javascript console grouping mechanism, so you can explore in detail the args, return values and state of the instance as each method executes.

instead of `:all` you can specify a single method, or an array of methods.  Use the array notation if you happen to want to trace just the method `:all`.

#### Breakpoints

```ruby
SomeClass.hypertrace break_on_enter: :foo
```

Will break on entry to `SomeClass#foo` and `self` will be set the instance. The equivalent `break_on_exit` method will also store the result in a javascript variable called `RESULT`.

#### Conditional Breakpoints

```ruby
SomeClass.hypertrace break_on_enter?: {foo: ->(arg1, arg2 ...) { ... }}
```

The proc will be called before each call to `SomeClass#foo`, and any args passed to foo will be matched to the args, and the proc's instance will be set the foo's instance.  If the proc returns a falsy value the breakpoint will be skipped.

#### Instrumenting Class methods

If the first argument is `:class` hypertrace will instrument the class methods.

```ruby
SomeClass.hypertrace :class instrument: :some_class_method
```

#### DSL

You can also use a simple DSL:

```ruby
SomeClass.hypertrace do
  instrument      [:foo, :bar]
  break_on_exit   :baz
  break_on_enter? :ralph do |p1, p2|
    # executes with self set the instance, p1, p2 will be the
    # first two args passed to ralph
    p1 == p2 # break if p1 == p2
  end
end
```

#### Switching it off

```ruby
SomeClass.hypertrace instrument: :none
```

#### Inside of classes

Of course you can switch hypertrace on inside of your classes for quick debugging.  Just remember that hypertrace applies
only to currently defined methods.

```ruby
SomeClass
  ...
  hypertrace instrument: :all
end
```

#### Works with Hyper-React (Reactrb)

If you hypertrace a React Component class you will get information on the component lifecycle, and the component state will include react state variables, and params (props) as well as normal instance variables.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hyper-trace'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hyper-trace

Once installed add `require 'hyper-trace'` to your application or component manifest file.  This gem works best if you are using Capybara or opal rspec, in which case you can reference the gem in the test application's manifest.


## Custom Class Definitions

If class instance responds to `hypertrace_format_instance` then that method will be called to format the state information.

The method will be passed a hypertrace context object that will respond to the following methods:

+ `format_instance(instance_vars = nil, &block)`  
log the default instance header information.  If instance_vars is nil then all instance vars will be printed.  Otherwise instance_vars should be an array of the instance vars to display.  The block will be executed to provide other details following the instance vars.
+ `safe_i(object)`:  
call inspect on an object will work even if the object is a native js object.
+ `safe_s(object)`:  
call to_s on an object safely
+ `log(s)`  
print a s to the log, nested at the current grouping level
+ `group(header, collapsed: false, &block)`  
create a new nesting group.  If collapsed is true then the group will be initially closed.  If block is present it will provide the contents of the group.

If the method `hypertrace_exclusions` is defined, it can return an array of methods names that will be not
be shown unless explicitly named.

For more details see the react_trace.rb module in this gem.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

This is a very simple work in progress.  Any and all help is requested.  Things to do:

2. Conditional tracing
2. Add ability to specify `to_s` and `inspect` methods for use during tracing
3. Add ability to specify `HyperTrace` delegator classes
5. Add some tests

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hyper-trace. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
