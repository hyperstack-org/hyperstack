class DisplayTicker < HyperComponent
  param :symbol
  param :on_cancel, type: Proc
  before_mount { @ticker = StockTicker.new(params.symbol, 10.seconds) }

  def status
    case @ticker.status
    when :loading
      'loading...'
    when :success
      "current price: #{@ticker.price}"
    when :failed
      "failed to get quote: #{@ticker.reason}"
    end
  end

  render(DIV) do
    SPAN { "#{params.symbol.upcase} #{status}" }
    BUTTON { 'cancel' }.on(:click) { params.on_cancel } unless @ticker.status == :loading
  end
end
