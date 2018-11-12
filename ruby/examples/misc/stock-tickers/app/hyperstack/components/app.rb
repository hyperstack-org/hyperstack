class App < HyperComponent
  before_mount { @symbols = Set.new }

  def add_symbol
    mutate @symbols << @_symbol_input.value.upcase
    @_symbol_input.value = ''
  end

  render do
    BS::Container(style: { margin: 20 }) do
      @symbols.sort.each do |symbol|
        DisplayTicker(symbol: symbol, key: symbol)
        .on(:cancel) { mutate @symbols.delete(symbol) }
      end
      BS::Row(style: { marginTop: 20 }) do
        BS::Col(sm: 4) do
          BS::InputGroup(class: 'mb-3') do
            BS::FormControl(dom: set(:_symbol_input), placeholder: 'New Stock Market Symbol')
            .on(:enter) { add_symbol }
            BS::InputGroup::Append() { BS::Button() { 'Add' } }
            .on(:click) { add_symbol }
          end
        end
      end
    end
  end
end
