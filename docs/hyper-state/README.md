
<img align="left" width="100" height="100" style="margin-right: 20px" src="https://github.com/hyperstack-org/hyperstack/blob/edge/docs/wip.png?raw=true" /> The `Hyperstack::State::Observable` module allows you to build classes that share their state with Hyperstack Components, and have those components update when objects in those classes change state.

## This Page Under Construction

The `Hyperstack::State::Observable` module allows you to build classes that share their state with Hyperstack Components, and have those components update when objects in those classes change state.

### Revisiting the Tic Tac Toe Game

The easiest way to understand how to use Hyperstate is by example.  If you you did not see the Tic Tac Toe example, then please review it now, as we are going to use this to demonstrate how the `Hyperstack::State::Observable` can be used in any Ruby class, to make that class work as a **Store** for your Hyperstack components.

Here is the revised Tic Tac Toe game using a *Store* to hold the game data.

```ruby
class Game
  include Hyperstack::State::Observable

  receives Hyperstack::Application::Boot do
    @history = [[]]
    @step = 0
  end

  class << self
    observer :player do
      @step.even? ? :X : :O
    end

    observer :current do
      @history[@step]
    end

    state_reader :history

    WINNING_COMBOS = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

    def current_winner?
      WINNING_COMBOS.each do |a, b, c|
        return current[a] if current[a] && current[a] == current[b] && current[a] == current[c]
      end
      false
    end

    mutator :handle_click! do |id|
      board = history[@step]
      return if current_winner? || board[id]

      board = board.dup
      board[id] = player
      @history = history[0..@step] + [board]
      @step += 1
    end

    mutator(:jump_to!) { |step| @step = step }
  end
end

class DisplayBoard < HyperComponent
  param :board

  def draw_square(id)
    BUTTON(class: :square, id: id) { board[id] }
    .on(:click) { Game.handle_click!(id) }
  end

  render(DIV) do
    (0..6).step(3) do |row|
      DIV(class: :board_row) do
        (row..row + 2).each { |id| draw_square(id) }
      end
    end
  end
end

class DisplayGame < HyperComponent
  def moves
    return unless Game.history.length > 1

    Game.history.length.times do |move|
      LI(key: move) { move.zero? ? "Go to game start" : "Go to move ##{move}" }
        .on(:click) { Game.jump_to!(move) }
    end
  end

  def status
    if (winner = Game.current_winner?)
      "Winner: #{winner}"
    else
      "Next player: #{Game.player}"
    end
  end

  render(DIV, class: :game) do
    DIV(class: :game_board) do
      DisplayBoard(board: Game.current)
    end
    DIV(class: :game_info) do
      DIV { status }
      OL { moves }
    end
  end
end
```
