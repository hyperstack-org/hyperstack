Debugging any UI code is difficult.  Hyperstack's declarative approach, and lack of redundant boilerplate helps a lot.  Simply having 1/4 the code base
to deliver the same functionality is going to make things easier.

However all that said, **Debugging UI Code is Difficult.**  The UI's main job is to deal with events coming from multiple directions and unpredictable sources, this makes tracking down failures difficult as timing can become an issue.

Here are few tips to go along with the other tools in this section (HyperSpec and HyperTrace) to make your life a bit easier.

### JavaScript Console

At any time during program execution you can breakout into the JavaScript console by simply adding the debugger keyword to your Ruby code.

If you have source maps turned on you will then be able to see your ruby code \(and the compiled JavaScript code\) and set browser breakpoints, examine values and continue execution.

> Important Note:  The Opal compiler will not handle the `debugger` keyword at the end of blocks, method definitions, or begin..end statements.  
```ruby
def buggy_method
  ...
  debugger # this will break add any expression on the next line to fix
end
```

You can also inspect Ruby objects from the JavaScript console.  The mapping between the Javascript and Ruby is fairly easy to follow thanks to the great Opal team.

Here are some tips: [https://dev.mikamai.com/2014/11/19/3-tricks-to-debug-opal-code-from-your-browser/](https://dev.mikamai.com/2014/11/19/3-tricks-to-debug-opal-code-from-your-browser/)

### The `puts` method is your friend

Anywhere in your HyperReact code you can simply puts any\_value which will display the contents of the value in the browser console. This can help you understand React program flow as well as how data changes over time.

```ruby
class Thing < Hyperstack::Component
  param initial_mode: 12

  before_mount do
    state.mode! params.initial_mode
    puts "before_mount params.initial_mode=#{params.initial_mode}"
  end

  after_mount do
    @timer = every(60) { force_update! }
    puts "after_mount params.initial_mode=#{params.initial_mode}"
  end

  render do
    div(class: :time) do
      puts "render params.initial_mode=#{params.initial_mode}"
      puts "render state.mode=#{state.mode}"
      ...
      end.on(:change) do |e|
        state.mode!(e.target.value.to_i)
        puts "on:change e.target.value.to_i=#{e.target.value.to_i}"
        puts "on:change (too high) state.mode=#{state.mode}" if state.mode > 100
      end
    end
  end
end
```

### HyperTrace

Sometimes popping in a trace can reveal a lot about what is going on.  [HyperTrace](hyper-trace.md) wraps your selected method calls in
a dump of incoming parameters, instance variable state, and return values.  You can also setup conditional
breakpoints.  So keep HyperTrace handy in your tool belt.

### HyperSpec

IMHO the best debugging tool is a spec.  As soon as you start creating a new feature, or find a bug, start
writing a spec.  Once you can reproduce the problem by running a spec, you are 90% of the way to fixing the problem,
and you will have another spec to add to your tests, making your app more robust.  [HyperSpec](hyper-spec/README.md) extends RSpec so that
can control and interrogate the client from within your specs, using Ruby code.
