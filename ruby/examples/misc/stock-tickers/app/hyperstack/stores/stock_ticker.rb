class StockTicker
  include Hyperstack::State::Observable

  state_reader :price
  attr_reader :symbol

  def initialize(symbol, update_interval = 5.minutes)
    @symbol = symbol
    fetch
    every(update_interval) { fetch }
  end

  def fetch
    puts "fetching #{@symbol}"
    HTTP.get("https://api.iextrading.com/1.0/stock/#{@symbol}/delayed-quote").then do |response|
      mutate @price = response.json[:delayedPrice]
    end
  end

  before_unmount do
    # just to demonstrate use of before_unmount - this is not needed
    # but if there were some other cleanups you needed you could put them here
    # however intervals (every) delays (after) and websocket receivers are all
    # cleaned up automatically
    puts "cancelling #{@symbol}"
  end

end
