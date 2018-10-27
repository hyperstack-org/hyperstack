class StockTicker
  include Hyperstack::State::Observable

  def fetch
    HTTP.get("https://api.iextrading.com/1.0/stock/#{@symbol}/delayed-quote").then do |response|
      mutate @price = response.json[:delayedPrice]
    end
  end

  def initialize(symbol, update_interval = 5.minutes)
    @symbol = symbol
    fetch
    every(update_interval) { fetch }
  end

  state_reader :price
  attr_reader :symbol
end
