# Our StockTicker class abstracts out fetching and updating the stock
# data for each ticker.

# By including the Hyperstack::State::Observable class we make our state
# changes observable by other Components and Observables.

class StockTicker
  include Hyperstack::State::Observable

  attr_reader  :symbol

  # state readers, these work like attr_readers, but
  # when the state is accessed (observed) it will be tracked
  # so the State system knows which components to update when
  # the state of the ticker changes

  state_reader :price
  state_reader :time
  state_reader :status
  state_reader :reason

  # when the ticker is initialized we save the value of symbol and
  # the update_interval in instance variables.
  # @status is initialized to :loading, and all future changes will
  # be marked with a call to mutate.
  # Finally we make our first fetch of the symbols stock data.

  def initialize(symbol, update_interval = 5.seconds)
    @symbol = symbol
    @update_interval = update_interval
    @status = :loading
    fetch
  end

  # Each fetch sets up a call to get the symbols delayed quote data.
  # when the fetch returns we record the status, the price,
  # and the time of the quote.

  # prefixing the state changes with mutate will signal any observers
  # that the state of this ticker has changed.

  # once we have updated the state we setup another fetch cycle

  # If the fetch fails, then we also update the status, and reason for the
  # failure.  If the reason is that the symbol is unknown then we do not
  # need to reattempt the fetch, but otherwise we will keep trying.

  def fetch
    HTTP.get("https://api.iextrading.com/1.0/stock/#{@symbol}/delayed-quote")
        .then do |resp|
          mutate @status = :success, @price = resp.json[:delayedPrice],
                 @time = Time.at(resp.json[:delayedPriceTime] / 1000)
          after(@update_interval) { fetch }
        end
        .fail do |resp|
          mutate @status = :failed, @reason = resp.body.empty? ? 'Network error' : resp.body
          after(@update_interval) { fetch } unless @reason == 'Unknown symbol'
        end
  end

  # just to demonstrate use of before_unmount - this is not needed
  # but if there were some other cleanups you needed you could put them here
  # however intervals (every) delays (after) and websocket receivers are all
  # cleaned up automatically

  before_unmount do
    puts "cancelling #{@symbol} ticker"
  end
end

StockTicker.hypertrace instrument: :all
