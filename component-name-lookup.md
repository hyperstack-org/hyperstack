#### Notes on how component names are looked up

Given:

```ruby

class Blat < React::Component::Base

  render do
    Bar()      
    Foo::Bar()
  end

end

class Bar < React::Component::Base
end

module Foo

  class Bar < React::Component::Base

    render do
      Blat()
      Baz()
    end
  end

  class Baz < React::Component::Base
  end

end
```

The problem is that method lookup is different than constant lookup.  We can prove it by running this code:

```ruby
def try_it(test, &block)
  puts "trying #{test}"
  result = yield
  puts "success#{': '+result.to_s if result}"
rescue Exception => e
  puts "failed: #{e}"
ensure
  puts "---------------------------------"
end

module Boom

  Bar = 12

  def self.Bar
    puts "   Boom::Bar says hi"
  end

  class Baz
    def doit
      try_it("Bar()") { Bar() }
      try_it("Boom::Bar()") {Boom::Bar()}
      try_it("Bar") { Bar }
      try_it("Boom::Bar") { Boom::Bar }
    end
  end
end



Boom::Baz.new.doit
```

which prints:

```text
trying Bar()
failed: Bar: undefined method `Bar' for #<Boom::Baz:0x774>
---------------------------------
trying Boom::Bar()
   Boom::Bar says hi
success
---------------------------------
trying Bar
success: 12
---------------------------------
trying Boom::Bar
success: 12
---------------------------------
```

[try-it](http://opalrb.org/try/?code:def%20try_it(test%2C%20%26block)%0A%20%20puts%20%22trying%20%23%7Btest%7D%22%0A%20%20result%20%3D%20yield%0A%20%20puts%20%22success%23%7B%27%3A%20%27%2Bresult.to_s%20if%20result%7D%22%0Arescue%20Exception%20%3D%3E%20e%0A%20%20puts%20%22failed%3A%20%23%7Be%7D%22%0Aensure%0A%20%20puts%20%22---------------------------------%22%0Aend%0A%0Amodule%20Boom%0A%20%20%0A%20%20Bar%20%3D%2012%0A%20%20%0A%20%20def%20self.Bar%0A%20%20%20%20puts%20%22%20%20%20Boom%3A%3ABar%20says%20hi%22%0A%20%20end%0A%0A%20%20class%20Baz%0A%20%20%20%20def%20doit%0A%20%20%20%20%20%20try_it(%22Bar()%22)%20%7B%20Bar()%20%7D%0A%20%20%20%20%20%20try_it(%22Boom%3A%3ABar()%22)%20%7BBoom%3A%3ABar()%7D%0A%20%20%20%20%20%20try_it(%22Bar%22)%20%7B%20Bar%20%7D%0A%20%20%20%20%20%20try_it(%22Boom%3A%3ABar%22)%20%7B%20Boom%3A%3ABar%20%7D%0A%20%20%20%20end%0A%20%20end%0Aend%0A%20%20%0A%0A%0ABoom%3A%3ABaz.new.doit)


What we need to do is:

1. when defining a component class `Foo`, also define in the same scope that Foo is being defined a method `self.Foo` that will accept Foo's params and child block, and render it.

2. As long as a name is qualified with at least one scope (i.e. `ModName::Foo()`) everything will work out, but if we say just `Foo()` then the only way I believe out of this is to handle it via method_missing, and let method_missing do a const_get on the method_name (which will return the class) and then render that component.

#### details

To define `self.Foo` in the same scope level as the class `Foo`, we need code like this:

```ruby
def register_component_dsl_method(component)
  split_name = component.name && component.name.split('::')
  return unless split_name && split_name.length > 2
  component_name = split_name.last
  parent = split_name.inject([Module]) { |nesting, next_const| nesting + [nesting.last.const_get(next_const)] }[-2]
  class << parent
    define_method component_name do |*args, &block|
      React::RenderingContext.render(name, *args, &block)
    end
    define_method "#{component_name}_as_node" do |*args, &block|
      React::Component.deprecation_warning("..._as_node is deprecated.  Render component and then use the .node method instead")
      send(component_name, *args, &block).node
    end
  end
end

module React
  module Component
    def self.included(base)
      ...
      register_component_dsl_method(base.name)
    end
  end
end
```

The component's method_missing function will look like this:

```ruby
def method_missing(name, *args, &block)
  if name =~ /_as_node$/
    React::Component.deprecation_warning("..._as_node is deprecated.  Render component and then use the .node method instead")
    method_missing(name.gsub(/_as_node$/,""), *args, &block).node
  else
    component = const_get name if defined? name
    React::RenderingContext.render(nil, component, *args, &block)
  end
end
```

### other related issues

The Kernel#p method conflicts with the <p> tag.   However the p method can be invoked on any object so we are going to go ahead and use it, and deprecate the para method.
