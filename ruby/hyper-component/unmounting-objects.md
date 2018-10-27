### Unmounting Objects

Consider a simple example of a class which provides an observable stock ticker:

```ruby
class StockTicker
  include Hyperstack::State::Observable

  def initialize(symbol, update_interval = 5.minutes)
    @symbol = symbol
    @interval = every(update_interval) do
      HTTP.get("https://api.iextrading.com/1.0/stock/#{@symbol}/delayed-quote").then do |response|
        mutate @price = response.json[:delayedPrice]
      end
    end
  end

  state_reader :price
  attr_reader :symbol
end
```

And here is a simple app to use it:

```ruby
class App < HyperComponent
  before_mount { @symbols = Set.new }
  render(DIV) do
    UL do
      @symbols.sort.each do |symbol|
        LI(key: symbol) do
          DisplayTicker(symbol: symbol, key: symbol)
          BUTTON { 'cancel' }.on(:click) { mutate @symbols.delete(symbol) }
        end
      end
    end
    INPUT(placeholder: 'enter a stock symbol').on(:keydown) do |evt|
      next unless evt.key_code == 13
      mutate @symbols << evt.target.value
    end
  end
end

class DisplayTicker < HyperComponent
  param :symbol
  before_mount { @ticker = StockerTicker.new(params.symbol) }
  render(DIV) do
    "#{params.symbol.upcase} current price: #{@ticker.price}"
  end
end
```

This is all well and good, and nice and simple.  The only problem is that when stock tickers are removed, we also want
to stop the HTTP fetch from occuring every `update_interval`.

To make this happen it would appear that we have to add the following methods and callbacks:

```ruby
class StockTicker
  def unmount
    @interval.abort
  end
end

class DisplayTicker < HyperComponent
  before_unmount { @ticker.unmount }
end
```

but the good news is you don't actually have to do this, as Hyperstack does it for you.  

Each class that has `Hyperstack::State::Observable` mixed gets a predefined `unmount` method, that will cancel all timers.

And when each component is unmounted, each instance variable of that component is checked to see if it can receive the `unmount`
method.  This process is followed recursively through out all the referenced objects, thus cleanly shutting down any asynchronous activities.

In addition if you need to add additional cleanup code to the class you can use the `before_unmount` callback within any Observable class,
just like you would in a Component. 
