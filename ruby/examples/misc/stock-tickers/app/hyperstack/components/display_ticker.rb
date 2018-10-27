class DisplayTicker < HyperComponent
  param :symbol
  param :on_cancel, type: Proc
  before_mount { @ticker = StockTicker.new(params.symbol, 10.seconds) }
  render(DIV) do
    case @ticker.status
    when :loading
      SPAN { "#{params.symbol.upcase} loading..."}
    when :success
      SPAN { "#{params.symbol.upcase} current price: #{@ticker.price}" }
    when :failed
      SPAN { "#{params.symbol.upcase} failed to get quote: #{@ticker.reason}"}
    end
    BUTTON { 'cancel' }.on(:click) { params.on_cancel } unless @ticker.status == :loading
  end
end
