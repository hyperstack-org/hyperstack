class App < HyperComponent
  before_mount { @symbols = Set.new }
  render(DIV) do
    UL do
      @symbols.sort.each do |symbol|
        LI(key: symbol) do
          DisplayTicker(symbol: symbol, key: symbol)
          BUTTON { 'cancel' }.on(:click) { mutate @symbols.delete(symbol) }
        end
      end
    end
    INPUT(placeholder: 'enter a stock symbol').on(:key_down) do |evt|
      next unless evt.key_code == 13
      mutate @symbols << evt.target.value
    end
  end
end
