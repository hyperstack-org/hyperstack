# Stores

Hyperloop Stores (similar to Flux Stores) exist to hold local application state. Components read state from Stores and render accordingly. This separation of concerns is an improvement in the overall architecture and makes your application easier to maintain.

**Why would we have Stores?** Let's examine that question through an example.

### Overloaded Components

Take the simple Component below which displays an initial discount then gives the user the option of taking a once only 'Lucky Dip' that will either increase or decrease their discount.

```ruby
class OfferLuckyDip < Hyperloop::Component
  state discount: 30

  render(DIV) do
    H1 {"Your discount is #{state.discount}%"}
    BUTTON { "Lucky Dip" }.on(:click) do
      mutate.discount(state.discount + rand(-5..5))
    end
  end
end
```

The Component will work as you would expect but there are two fundamental problems with this design:

+ Firstly, the discount (state) is tied to the Component itself. This is a problem as we might have other Components on the page which need to also see and interact with the discount. **We need a better place than in our Components to keep application state.**
+ Our business logic (discounts start at 30% and the lucky dip increases or decreases by 5%) is all wrapped up with our presentational code. This makes our application fragile and difficult to evolve. **Our application logic should be separate from our display logic.**

We will fix these problems but first implementing a Hyperloop Store to keep our application state and business logic out of our Components.

Later in this overview, we will go one step further and move our business logic out of the Store into an Operation but for now, the first step will be a big improvement.

### A simple Store

Stores are where the state of your Application lives. Anything but a completely static web page will have dynamic states that change because of user inputs, the passage of time, or other external events.

You can also create Stores by subclassing `Hyperloop::Store` or `Hyperloop::Store::Mixin` can be mixed into any class to turn it into a Flux Store.

Components that read a Store's state will automatically update when the state changes. Stores are simply Ruby classes that keep the dynamic parts of the state in special state variables.

First, let's add a Store and refactor our Component to use the Store:

```ruby runable
class Discounter < Hyperloop::Store
   state discount: 30, scope: :class, reader: true
  def self.lucky_dip!
    mutate.discount( state.discount + rand(-5..5) )
  end
end

class OfferLuckyDip < Hyperloop::Component
  render(DIV) do
    H1 {"Your discount is #{Discounter.discount}%"}
    BUTTON { "Lucky Dip" }.on(:click) do
      Discounter.lucky_dip!
    end
  end
end
```

You will notice a few things in the code above:

+ Notice how we use `mutate` to change the value of a state variable.
+ We do not create an instance of the Discounter class but instead access the class methods of the Store `Discounter.lucky_dip!` so that all Components will be using the same 'class instance' of the Store.
+ `Discounter.discount` is a reader class method that was added to the Store for us by `state discount: 30, scope: :class, reader: true` which saved us a lot of typing!

Stores can also receive dispatches from Operations - we will come to that later in this overview. In Hyperloop it is perfectly legitimate to interact with a Store through its class methods as we have done above.

### Sharing Stores

Components share state through Stores. Without the Store architecture, Components would need to pass state between themselves as params and this all becomes very clumsy.

Lets explore and example where Components share a Store:

```ruby runable
class TopLevelComponent < Hyperloop::Component
  render do
    DIV(class: 'container') do
      H1 { "Components sharing a Store" }
      TypeAlong()
      Buttons()
    end
  end
end

class MyStore < Hyperloop::Store
  state :value, reader: true, scope: :class
  def self.set_value! value
    mutate.value value
  end
  def self.clear!
    mutate.value ""
  end
end

class TypeAlong < Hyperloop::Component
  render(DIV) do
    INPUT(type: :text, value: MyStore.value ).on(:change) do |e|
      MyStore.set_value! e.target.value
    end
    P { "#{ MyStore.value }" }
  end
end

class Buttons < Hyperloop::Component
  render(DIV) do
    BUTTON(class: 'btn btn-primary') { 'See the value' }.on(:click) do
      alert "MyStore value is '#{ MyStore.value }'"
    end
    BUTTON(class: 'btn btn-link') { 'Clear' }.on(:click) do
      MyStore.clear!
    end
  end
end
```

You will notice in the code above:

+ We laid our page out using a TopLevelComponent who's job it was to render the other Components. This is a typical pattern in Hyperloop, an HTML page can consist of a simple DIV and one TopLevelComponent and all rendering is done by that Component. Often this will contain a router as each new 'page' will be rendered in this DIV.

+ We are using a class instance of MyStore so all the Components on the page will share the same instance. Note how we defined `state :value, reader: true, scope: :class` and also how the methods are class methods `def self.clear!`
+ The bang notation (!) is a matter of style, but used here to indicate a mutation.


That concludes the introduction to Stores. To learn more about Stores please see the [Tutorials](/tutorials) and also the comprehensive [Docs](/docs/architecture)

Next we will cover [Models](start/models)

------------------------------------
