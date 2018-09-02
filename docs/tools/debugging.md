# Debugging

## Debugging tips

Tips, good practice will help you debugging your Hyperloop application.

### JavaScript Console

At any time during program execution you can breakout into the JavaScript console by simply adding a line of back-ticked JavaScript to your ruby code:

`debugger;`

If you have source maps turned on you will then be able to see your ruby code (and the compiled JavaScript code) and set browser breakpoints, examine values and continue execution. See Opal Source Maps if you are not seeing source maps.

You can also inspect ruby objects from the JavaScript console.

Here are some tips: https://dev.mikamai.com/2014/11/19/3-tricks-to-debug-opal-code-from-your-browser/

### Puts is your friend

Anywhere in your HyperReact code you can simply puts any_value which will display the contents of the value in the browser console. This can help you understand React program flow as well as how data changes over time.

```ruby
class Thing < Hyperloop::Component
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
