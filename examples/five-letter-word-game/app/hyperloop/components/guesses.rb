class Guesses < React::Component::Base
  render(DIV) do
    OL do
      Store.my_guesses.each { |guess, no_correct| LI { "#{no_correct} in '#{guess}'" } }
    end
    BUTTON { 'quit' }.on(:click) { Ops::YouWin message: 'I quit' } unless Store.game_over?
  end
end
