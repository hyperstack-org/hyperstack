class DisplayTicker < HyperComponent
  param :symbol
  raises :cancel
  before_mount { @ticker = StockTicker.new(@Symbol, 10.seconds) }

  def status
    case @ticker.status
    when :loading
      BS::Col(sm: 10) { 'loading...' }
    when :success
      BS::Col(class: 'text-right', sm: 3) { 'price' }
      BS::Col(class: 'text-right', sm: 3) { '%.2f' % @ticker.price }
      BS::Col(sm: 4) { "at #{@ticker.time.strftime('%I:%M:%S')}" }
    when :failed
      BS::Col(sm: 10) { "failed to get quote: #{@ticker.reason}" }
    end
  end

  render do
    BS::Row() do
      BS::Col(sm: 1) { @Symbol.upcase }
      status
      BS::Col(sm: 1) do
        BS::Button(class: :close) { "\u00D7" }
        .on(:click) { cancel! } unless @ticker.status == :loading
      end
    end
  end
end
