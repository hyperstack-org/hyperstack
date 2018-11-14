class DisplayTicker < HyperComponent
  param    :symbol
  triggers :cancel
  before_mount { @_ticker = StockTicker.new(@Symbol, 10.seconds) }

  def status
    case @_ticker.status
    when :loading
      BS::Col(sm: 10) { 'loading...' }
    when :success
      BS::Col(class: 'text-right', sm: 3) { 'price' }
      BS::Col(class: 'text-right', sm: 3) { '%.2f' % @_ticker.price }
      BS::Col(sm: 4) { "at #{@_ticker.time.strftime('%I:%M:%S')}" }
    when :failed
      BS::Col(sm: 10) { "failed to get quote: #{@_ticker.reason}" }
    end
  end

  render do
    BS::Row() do
      BS::Col(sm: 1) { @Symbol.upcase }
      status
      BS::Col(sm: 1) do
        BS::Button(class: :close) { "\u00D7" }
        .on(:click) { cancel! } unless @_ticker.status == :loading
      end
    end
  end
end
