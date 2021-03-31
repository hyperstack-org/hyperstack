## Notes

### Blocks in Ruby

Ruby methods may *receive* a block which is simply an anonymous function.  

The following code in Ruby:

```ruby
some_method(1, 2, 3) { |x| puts x }
```
is roughly equivilent to this Javascript
```JavaScript
some_method(1, 2, 3 function(x) { console.log(x) })
```
In Ruby blocks may be specified either using `do ... end` or with `{ ... }`:

```Ruby
some_method { an_expression }
# or
some_method do
  several
  expressions
end
```
Standard style reserves the `{ ... }` notation for single line blocks, and `do ... end` for multiple line blocks.

### Component Instances

Currently when generating a component the actual value returned after processing by React is an instance of class
`Element`.  The long term plan is to merge these two concepts back together so that Element instances and
Component instances will be the same.  The major difference at the moment is that an Element carries all the data
needed to create a Component Instance, but has not yet been rendered.  Through out this document we will use
element and component instance interchangeably.

### Ruby Hash Params

In Ruby if the final argument to a method is a hash you may leave the `{...}` off:

```RUBY
some_method(1, 2, {a: 2, b: 3}) # same as
some_method(1, 2, a: 2, b: 3)
```

### The HyperComponent Base Class

By convention all your components inherit from the `HyperComponent` base class, which would typically look like this:

```ruby
# components/hyper_component.rb
class HyperComponent
  # All component classes must include Hyperstack::Component
  include Hyperstack::Component
  # The Observable module adds state handling
  include Hyperstack::State::Observable
  # The following turns on the new style param accessor
  # i.e. param :foo is accessed by the foo method
  param_accessor_style :accessors
end
```
> The Hyperstack Rails installer and generators will create this class for you if it does not exist, or you may copy the
above to your `components` directory.

Having an application wide `HyperComponent` class allows you to modify component behavior on an application basis, similar to the way Rails uses `ApplicationRecord` and `ApplicationController` classes.

> This is just a convention.  Any class that includes the `Hyperstack::Component` module can be used as a Component.  You also do not have
to name it `HyperComponent`.  For example some teams prefer `ApplicationComponent` more closely following the
Rails convention.  If you use a different name for this class be sure to set the `Hyperstack.component_base_class` setting so the
Rails generators will use the proper name when generating your components.  **[more details...](../rails-installation/generators.md#specifying-the-base-class)**

### Abstract and Concrete Components

An *abstract* component class is intended to be the base class of other components, and thus does not have a render block.
A class that defines a render block is a concrete class.  The
distinction between *abstract* and *concrete* is useful to distinguish classes like `HyperComponent` that are intended
to be subclassed.

Abstract classes are often used to share common code between subclasses.

### Word Count Method

```RUBY
def word_count(text)
  text.downcase                      # all lower case
      .gsub(/\W/, ' ')               # get rid of special chars
      .split(' ')                    # divide into an array of words
      .group_by(&:itself)            # group into arrays of the same words
      .map{|k, v| [k, v.length]}     # convert to [word, # of words]
      .sort { |a, b| b[1] <=> a[1] } # sort descending (that was fun!)
end
```

### Ownership

In the Avatar example instances of `Avatar` _own_ instances of `ProfilePic` and `ProfileLink`. In Hyperstack (like React), **an owner is the component that sets the `params` of other components**. More formally, if a component `X` is created in component `Y`'s `render` method, it is said that `X` is _owned by_ `Y`. As will be discussed later a component cannot mutate its `params` — they are always consistent with what its owner sets them to. This fundamental invariant leads to UIs that are guaranteed to be consistent.

It's important to draw a distinction between the owner-owned-by relationship and the parent-child relationship. The owner-owned-by relationship is specific to Hyperstack/React, while the parent-child relationship is simply the one you know and love from the DOM. In the example above, `Avatar` owns the `DIV`, `ProfilePic` and `ProfileLink` instances, and `DIV` is the **parent** \(but not owner\) of the `ProfilePic` and `ProfileLink` instances.

```ruby
class Avatar < HyperComponent
  param :user_name

  render do # this can be shortened to render(DIV) do - see the previous section
    DIV do
      ProfilePic(user_name: user_name)  # belongs to Avatar, owned by DIV
      ProfileLink(user_name: user_name) # belongs to Avatar, owned by DIV
    end
  end
end

class ProfilePic < HyperComponent
  param :user_name
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

### Generating Keys

Every Hyperstack object whether its a string, integer, or some complex class responds to the `to_key` method.
When you provide a component's key parameter with any object, the object's `to_key` method will be called, and
return a unique key appropriate to that object.

For example strings, and numbers return themselves.   Other complex objects return the internal `object_id`, and
some classes provide their own `to_key` method that returns some invariant value for each instance of that class.  HyperModel records
return the database id for example.

If you are creating your own data classes keep this in mind.  You simply define a `to_key` method on the class
that returns some value that will be unique to that instance.  And don't worry if you don't define a method, it will
default to the one provided by Hyperstack.

### Proper Use Of Keys

For best results the `key` is supplied at highest level possible.
> NOTE THIS MAY NO LONGER BE AN ISSUE IN LATEST REACT)

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

### Ruby Procs

A core class of objects in Ruby is the *Proc*.  A Proc (Procedure) is an
object that can be *called*.

```Ruby
some_proc.call(1, 2, 3)
```

Ruby has several ways to create procs:

```Ruby
# create a proc that will add its three parameters together
# using Proc.new
some_proc = Proc.new { |a, b, c| a + b + c }
# using the lambda method:
some_proc = lambda { |a, b, c| a + b + c }
# or the hash rocket notation:
some_proc = -> (a, b, c) { a + b + c }
# using a method (assuming self responds to foo)
some_proc = method(:foo)
```

And there are several more ways, each with its differences and uses.  You can
find lots of details on Procs by searching online.  **[Here is a good article to get you started...](https://blog.appsignal.com/2018/09/04/ruby-magic-closures-in-ruby-blocks-procs-and-lambdas.html)**

The most common ways you will use Procs in your Hyperstack code is to define
either lifecycle or component callbacks:

```Ruby
class Foo < HyperComponent
  before_mount :do_it_before
  after_mount { puts "I did it after" }
  render do
    BUTTON(on_click: ->() { puts "clicked Using a lambda" } ) { "click me" }
    BUTTON { "no click me" }.on(:click) { puts "clicked using the on method" }
  end
  def do_it_before
    puts "I did it before"
  end
end
```

The different ways of specifying callbacks allow you to keep your code clear and consise, but in the end they do the same thing.

> Note that there are subtle differences between Proc.new and lambda, that are beyond the scope of this note.

### Javascript

Opal-Ruby uses the backticks and `%x{ ... }` to drop blocks of Javascript code directly into your Ruby code.

```ruby
def my_own_console(message)
  # crab-claws can be used to escape back out to Ruby
  `console.log(#{message})`
end
```

Both the backticks and `%x{ ... }` work the same, but the `%{ ... }` notation is useful for multiple lines of code.

### How Importing Works

Hyperstack automates as much of the process as possible for bridging between React and Javascript, however you do have
lower level control as needed.

Let's say you have an existing React Component written in Javascript that you would like to access from Hyperstack.

Here is a simple hello world component:

```javascript
window.SayHello = class extends React.Component {
  constructor(props) {
    super(props);
    this.displayName = "SayHello"
  }
  render() { return React.createElement("div", null, "Hello ", this.props.name); }
}
```

> I'm sorry I can't resist.  Really?  
```ruby
class SayHello < HyperComponent
  param :name
  render(DIV) { "Hello #{name}"}
end
```
In what world is the Ruby not much better than that JS hot mess.

Assuming that this component is loaded some place in your assets, you can then access this from Hyperstack by creating a wrapper Component:

```ruby
class SayHello < HyperComponent
  imports 'SayHello'
end

class MyBigApp < HyperComponent
  render(DIV) do
    # SayHello will now act like any other Hyperstack component
    SayHello name: 'Matz'
  end
end
```

The `imports` directive takes a string \(or a symbol\) and will simply evaluate it and check to make sure that the value looks like a React component, and then set the underlying native component to point to the imported component.

Normally you do not have to use `imports` explicitly.  When Hyperstack finds a component named in your code that is undefined it searches for
a Javascript class whose matches, and which acts like a React component class.  Once find it creates the class and imports for you.

You may also turn off the autoimport function if necessary in your `hyperstack.rb` initializer:

```ruby
# do not use the auto-import module
Hyperstack.cancel_import    'hyperstack/component/auto-import'
```

### The Enter Event
The :enter event is short for catching :key_down and then checking for a key code of 13.
```ruby
class YouSaid < HyperComponent
  state_accessor :value
  render(DIV) do
    INPUT(value: value)
    .on(:enter) do
      alert "You said: #{value}"
      self.value = ""
    end
    .on(:change) do |e|
      self.value = e.target.value
    end
  end
end
```
