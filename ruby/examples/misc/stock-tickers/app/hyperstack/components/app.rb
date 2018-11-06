class App < HyperComponent
  before_mount { @symbols = Set.new }

  def add_symbol
    mutate @symbols << @SymbolInput.value.upcase
    @SymbolInput.value = ''
  end

  render do
    BS.container(style: { margin: 20 }) do
      @symbols.sort.each do |symbol|
        display_ticker(symbol: symbol, key: symbol)
        .on(:cancel) { mutate @symbols.delete(symbol) }
      end
      BS.row(style: { marginTop: 20 }) do
        BS.col(sm: 4) do
          BS.input_group(class: 'mb-3') do
            BS.form_control(ref: assign_to(:SymbolInput), placeholder: 'New Stock Market Symbol')
            .on(:enter) { add_symbol }
            BS::InputGroup.append { BS.button { 'Add' } }
            .on(:click) { add_symbol }
          end
        end
      end
    end
  end
end
