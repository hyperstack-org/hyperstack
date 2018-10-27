class DisplayTicker < HyperComponent
  param :symbol
  param :on_cancel, type: Proc
  before_mount { @ticker = StockTicker.new(params.symbol, 10.seconds) }
  render(DIV) do
    SPAN { "#{params.symbol.upcase} current price: #{@ticker.price}" }
    BUTTON { 'cancel' }.on(:click) { params.on_cancel }
  end
end
