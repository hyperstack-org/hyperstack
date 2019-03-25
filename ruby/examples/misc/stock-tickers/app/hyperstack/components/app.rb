class App < HyperComponent

  # To make our code easy to read we use the following conventions for
  # instance variables (state):
  #   @snake_case  : reactive instance variable that will trigger rerenders
  #   @_snake_case : non-reactive instance variable that will never be mutated
  #   @CamelCase   : a component param (this convention is inforced by Hyperstack)

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
            BS::FormControl(ref: set_jq(:_symbol_input), placeholder: 'New Stock Market Symbol')
            .on(:enter) { add_symbol }
            BS::InputGroup::Append() { BS::Button() { 'Add' } }
            .on(:click) { add_symbol }
          end
        end
      end
    end
  end
end
