# HyperSpec

[![Build Status](https://travis-ci.org/ruby-hyperloop/hyper-spec.svg?branch=master)](https://travis-ci.org/ruby-hyperloop/hyper-spec)

With HyperSpec you can run *isomorphic* specs for all your Hyperloop code using RSpec.  Everything runs as standard RSpec test specs.  

For example if you have a component like this:

```ruby
class SayHello < React::Component::Base
  param :name
  render(DIV) do
    "Hello there #{params.name}"
  end
end
```

Your test spec would look like this:

```ruby
describe 'SayHello', js: true do
  it 'has the correct content' do
    mount "SayHello", name: 'Fred'
    expect(page).to have_content('Hello there Fred')
  end
end
```

The `mount` method will setup a blank client window, and *mount* the named component in the window, passing any parameters.

Notice that the spec will need a client environment so we must set `js: true`.

The `mount` method can also take a block which will be recompiled and set to the client before mounting the component.  You can place any client side code in the mount block including the definition of components.

```ruby
describe "the mount's code block", js: true do
  it 'will be recompiled on the client' do
    mount 'ShowOff' do
      class ShowOff < React::Component::Base
        render(DIV) { 'Now how cool is that???' }
      end
    end
    expect(page).to have_content('Now how cool is that???' )
  end
end
```

## Why?

Hyperloop wants to make the server-client divide as transparent to the developer as practical.  Given this, it makes sense that the testing should also be done with as little concern for client versus server.  

HyperSpec allows you to directly use tools like FactoryGirl (or Hyperloop Operations) to setup some test data, then run a spec to make sure that a component correctly displays, or modifies that data.  You can use Timecop to manipulate time and keep in sync between the server and client.  This makes testing easier and more realistic without writing a lot of redundant code.


## Installation

Add this line to your application's Gemfile in the test section:

```ruby
gem 'hyper-spec'
```

Execute:

    $ bundle install

and then in your spec_helper.rb file

```ruby
require 'hyper-spec'
```

You will also need to install selenium, poltergeist and firefox version **46.0.1** (ff latest still does not play well with selenium).

Sadly at this time the selenium chrome driver does not play nicely with Opal, so you can't use Chrome.  We are working on getting rid of the whole selenium business.  Stay tuned.

## Environment Variables

You can set `DRIVER` to `ff` to run the client in Firefox and see what is going on.  By default tests will run in poltergeist which is quicker, but harder to debug problems.

```
DRIVER=ff bundle exec rspec
```

## Spec Helpers

HyperSpec adds the following spec helpers to your test environment

+ `mount`
+ `client_option` and `client_options`
+ `on_client`
+ `isomorphic`
+ `evaluate_ruby`
+ `expect_evaluate_ruby`
+ `expect_promise`
+ call back and event history methods
+ `pause`
+ `attributes_on_client`
+ `size_window`
+ `add_class`

#### The `mount` Method

`mount` takes the name of a component, prepares an empty test window, and mounts the named component in the window.  
You may give a block to `mount` which will be recompiled on the client, and run *before* mounting.  This means that the component
mounted may be actually defined in the block, which is useful for setting up top level wrapper components, which will invoke your component under test.  You can also modify existing components for white box testing, or local fixture data, constants, etc.

`mount` may also be given a hash of the parameters to be passed to the component.

```ruby
mount 'Display', test: 123 do
  class Display < React::Component::Base
    param :test
    render(DIV) { params.test.to_s }
  end
end
```

#### The `client_option` Method

There are several options that control the mounting process.  Use `client_option` (or `client_options`) before accessing any client side to set any of these options:

+ `render_on`: `:server_only`, `:client_only`, or `:both`, default is client_only.
+ `layout`: specify the layout to be used.  Default is :none.
+ `style_sheet`: specify the name of the style sheet to be loaded. Defaults to the application stylesheet.
+ `javascript`: specify the name of the javascript asset file to be loaded. Defaults to the application js file.

For example:

```ruby
it "can be rendered server side only" do
  client_option render_on: :server_only
  mount 'SayHello', name: 'George'
  expect(page).to have_content('Hello there George')
  # Server only means no code is downloaded to the client
  expect(evaluate_script('typeof React')).to eq('undefined')
end
```

If you need to pull in alternative style sheets and javascript files, the recommended way to do this is to

1. Add them to a `specs/assets/stylesheets` and `specs/assets/javascripts` directory and
2. Add the following line to your `config/environment/test.rb` file:  
  ```ruby
    config.assets.paths << ::Rails.root.join('spec', 'assets', 'stylesheets').to_s
    config.assets.paths << ::Rails.root.join('spec', 'assets', 'javascripts').to_s
  ```

This way you will not pollute your application with these 'test only' files.

*The javascript spec asset files can be `.rb` files and contain ruby code as well.  See the specs for examples!*

#### The `on_client` Method

`on_client` takes a block and compiles and runs it on the client.  This is useful in setting up test constants and client only fixtures.

Note that `on_client` needs to *proceed* any calls to `mount`, `evaluate_ruby`, `expect_evaluate_ruby` or `expect_promise` as these methods will initiate the client load process.

#### The `isomorphic` Method

Similar to `on_client` but the block is *also* run on the server.  This is useful for setting constants shared by both client and server, and modifying behavior of isomorphic classes such as ActiveRecord models, and HyperOperations.

```ruby
isomorphic do
  class SomeModel < ActiveRecord::Base
    def fake_attribute
      12
    end
  end
end
```

#### The `evaluate_ruby` Method

Takes either a string or a block, dynamically compiles it, downloads it to the client and runs it.

```ruby
evaluate_ruby do
  i = 12
  i * 2
end
# returns 24

isomorphic do
  def factorial(n)
    n == 1 ? 1 : n * factorial(n-1)
  end
end

expect(evaluate_ruby("factorial(5)")).to eq(factorial(5))
```

`evaluate_ruby` can also be very useful for debug.  Set a breakpoint in your test, then use `evaluate_ruby` to interrogate the state of the client.

#### The `expect_evaluate_ruby` Method

Combines expect and evaluate methods:

```ruby
expect_evaluate_ruby do
  i = 1
  5.times { |n| i = i*n }
  i
end.to eq(120)
```

#### The `expect_promise` Method

Works like `expect_evaluate_ruby` but is used with promises.  `expect_promise` will hang until the promise resolves and then return to the results.

```ruby
expect_promise do
  Promise.new.tap do |p|
    after(2) { p.resolve('hello') }
  end
end.to eq('hello')
```

#### Call Back and Event History Methods

HyperReact components can *generate* events and perform callbacks.  HyperSpec provides methods to test if an event or callback was made.

```ruby
mount 'CallBackOnEveryThirdClick' do
  class CallBackOnEveryThirdClick < React::Component::Base
    param :click3, type: Proc
    def increment_click
      @clicks ||= 0
      @clicks = (@clicks + 1)
      params.click3(@clicks) if @clicks % 3 == 0
    end
    render do
      DIV(class: :tp_clicker) { "click me" }
      .on(:click) { increment_click }
    end
  end
end

7.times { page.click('#tp_clicker') }
expect(callback_history_for(:click3)).to eq([[3], [6]])
```

Note that for things to work, the param must be declared as a `type: Proc`.

+ `callback_history_for`: the entire history given as an array of arrays
+ `last_callback_for`: same as `callback_history_for(xxx).last`
+ `clear_callback_history_for`: clears the array (userful for repeating test variations without remounting)
+ `event_history_for, last_event_for, clear_event_history_for`: same but for events.

#### The `pause` Method

For debugging.  Everything stops, until you type `go()` in the client console.  Running binding.pry also has this effect, and is often sufficient, however it will also block the server from responding unless you have a multithreaded server.

#### The `attributes_on_client` Method

*This feature is currently untested - use at your own risk.*

This reads the value of active record model attributes on the client.

In other words the method `attributes_on_client` is added to all ActiveRecord models.   You then take a model you have instance of on the server, and by passing the Capybara page object, you get back the attributes for that same model instance, currently on the client.

```ruby
expect(some_record_on_server.attributes_on_client(page)[:fred]).to eq(12)
```

Note that after persisting a record the client and server will be synced so this is mainly useful for debug or in rare cases where it is important to interrogate the value on the client before its persisted.

#### The `size_window` Method

Sets the size of the test window.  You can say:
`size_window(width, height)` or pass one of the following standard sizes:  to one of the following standard sizes:

+ small: 480 X 320
+ mobile: 640 X 480
+ tablet: 960 X 640
+ large: 1920 X 6000
+ default: 1024 X 768

example: `size_window(:mobile)`

You can also modify the standard sizes with `:portrait`

example: `size_window(:table, :portrait)`

You can also specify the size by providing the width and height.

example: `size_window(600, 600)`

size_window with no parameters is the same as `size_window(:default)`

Typically you will use this in a `before(:each)` or `before(:step)` block

#### The `add_class` Method

Sometimes it's useful to change styles during testing (mainly for debug so that changes on screen are visible.)

The `add_class` method takes a class name (as a symbol or string), and hash representing the style.

```ruby
it "can add classes during testing" do
  add_class :some_class, borderStyle: :solid
  mount 'StyledDiv' do
    class StyledDiv < React::Component::Base
      render(DIV, id: 'hello', class: 'some_class') do
        'Hello!'
      end
    end
  end
  expect(page.find('#hello').native.css_value('border-right-style')).to eq('solid')
end
```

## Integration with the Steps gem

The [rspec-steps gem](https://github.com/LRDesign/rspec-steps) can be useful in doing client side testing.  Without rspec-steps, each test spec will cause a reload of the browser window.  While this insures that each test runs in a clean environment, it is typically not necessary and can really slow down testing.

The rspec-steps gem will run each test without reloading the window, which is usually fine.

Checkout the rspec-steps example in the `hyper_spec.rb` file for an example.

*Note that hopefully in the near future we are going to build a custom capybara driver that will just directly talk to Hyperloop on the client side.  Once this is in place these troubles should go away! - Volunteers welcome to help!*

## Timecop Integration

HyperSpec is integrated with [Timecop](https://github.com/travisjeffery/timecop) to freeze, move and speed up time.  The client and server times will be kept in sync when you use any these Timecop methods:

+ `freeze`:  Freezes time at the specified point in time (default is Time.now)
+ `travel`:  Time runs normally forward from the point specified.
+ `scale`:   Like travel but times runs faster.
+ `return`:  Return to normal system time.

For example:
```ruby
Timecop.freeze # freeze time at current time
# ... test some stuff
Timecop.freeze Time.now+10.minutes # move time forward 10 minutes
# ... check to see if expected events happened etc
Timecop.return
```

```ruby
Timecop.scale 60, Time.now-1.year do
  # Time will begin 1 year ago but advance 60 times faster than normal
  sleep 10
  # still sleeps for 10 seconds YOUR time, but server and client will
  # think 10 minutes have passed
end
# no need for Timecop.return if using the block style
```

See the Timecop [README](https://github.com/travisjeffery/timecop/blob/master/README.markdown) for more details.

There is one confusing thing to note:  On the server if you `sleep` then you will sleep for the specified number of seconds when viewed *outside* of the test.  However inside the test environment if you look at Time.now, you will see it advancing according to the scale factor.  Likewise if you have a `after` or `every` block on the client, you will wait according to *simulated* time.

## Common Problems

If you are getting failures on Poltergeist but not Firefox, make sure you are not requiring `browser` in your components.rb.
Requiring `browser/interval` or `browser/delay` is okay.

## Development

After checking out the repo, run bundle install and you should be good to go.

Tests are run either by running `rake` or for more control:

```
DRIVER=ff bundle exec rspec spec/hyper_spec.rb
```

where DRIVER can be either `ff` (firefox) or `pg` (poltergeist - default).

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hyper-spec. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
