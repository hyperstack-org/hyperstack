class DisplayTicker < HyperComponent
  param  :symbol
  raises :cancel
  before_mount { @ticker = StockTicker.new(@Symbol, 10.seconds) }

  def status
    case @ticker.status
    when :loading
      BS.col(sm: 10) { 'loading...' }
    when :success
      BS.col(class: 'text-right', sm: 3) { 'price' }
      BS.col(class: 'text-right', sm: 3) { '%.2f' % @ticker.price }
      BS.col(sm: 4) { "at #{@ticker.time.strftime('%I:%M:%S')}" }
    when :failed
      BS.col(sm: 10) { "failed to get quote: #{@ticker.reason}" }
    end
  end

  render do
    BS.row do
      BS.col(sm: 1) { @Symbol.upcase }
      status
      BS.col(sm: 1) do
        BS.button(class: :close) { "\u00D7" }
        .on(:click) { cancel! } unless @ticker.status == :loading
      end
    end
  end
end
