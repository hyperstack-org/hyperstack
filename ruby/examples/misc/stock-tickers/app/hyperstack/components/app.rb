class App < HyperComponent
  before_mount { @symbols = Set.new }
  render(DIV) do
    UL do
      @symbols.sort.each do |symbol|
        LI(key: symbol) do
          DisplayTicker(symbol: symbol)
          .on(:cancel) { mutate @symbols.delete(symbol) }
        end
      end
    end
    INPUT(placeholder: 'enter a new stock symbol')
    .on(:key_down) do |evt|
      next unless evt.key_code == 13
      mutate @symbols << evt.target.value.upcase
      evt.target.value = ''
    end
  end
end
