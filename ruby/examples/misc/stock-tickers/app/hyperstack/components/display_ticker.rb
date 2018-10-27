class DisplayTicker < HyperComponent
  param :symbol
  before_mount { @ticker = StockTicker.new(params.symbol) }
  render(DIV) do
    "#{params.symbol.upcase} current price: #{@ticker.price}"
  end
end
