At this point if you have been reading sequentially through these chapters you know enough to put together a simple tic-tac-toe game.

### The Game Board

The board is represented by an array of 9 cells. Cell 0 is the top left square, and cell 8 is the bottom right.

Each cell will contain nil, an `:X` or an `:O`.

### Displaying the Board

The `DisplayBoard` component displays a board.  `DisplayBoard` accepts a `board` param, and will fire back a `clicked_at` event when the user clicks one of the squares.

A small helper function `draw_squares` draws an individual square which is displayed as a `BUTTON`.  A click handler is attached which
will fire the `clicked_at` event with the appropriate cell id.

Notice that `DisplayBoard` has no internal state of its own.  That is handled by the `DisplayGame` component.

```ruby
class DisplayBoard < HyperComponent
  param :board
  fires :clicked_at

  def draw_square(id)
    BUTTON(class: :square, id: id) { board[id] }
    .on(:click) { clicked_at!(id) }
  end

  render(DIV) do
    (0..6).step(3) do |row|
      DIV(class: :board_row) do
        (row..row + 2).each { |id| draw_square(id) }
      end
    end
  end
end
```

### The Game State

The `DisplayGame` component has two state variables:  
+ `@history` which is an array of boards, each board being the array of cells.
+ `@step` which is the current step in the history (we begin at zero)

`@step` and `@history` allows the player to move backwards or forwards and replay parts of the game.

These are initialized in the `before_mount` callback.  Because Ruby will adjust the array size as needed
and return nil if an array value is not initialized, we can simply initialize the board to an empty array.

There are three *reader* methods that read the state:

+ `player` returns the current player's token.  The first player is always `:X` so even steps
are `:X`, and odd steps are `:O`.
+ `current` returns the board at the current step.
+ `history` uses state_reader to encapsulate the history state.

Encapsulated access to state in reader methods like this is not necessary but is good practice

```ruby
class DisplayGame < HyperComponent
  before_mount do
    @history = [[]]
    @step = 0
  end

  def player
    @step.even? ? :X : :O
  end

  def current
    @history[@step]
  end

  state_reader :history
end
```

### Calculating the Winner Based on the Game State

We also have a `current_winner?` method that will return the winning player or nil based on the value of the current board:

```ruby
class DisplayGame < HyperComponent
  WINNING_COMBOS = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6]
  ]

  def current_winner?
    WINNING_COMBOS.each do |a, b, c|
      return current[a] if current[a] && current[a] == current[b] && current[a] == current[c]
    end
    false
  end
end
```

### Mutating the Game State

There are two mutator methods that change state:
+ `handle_click!` is called with the id of the square when a user clicks on a square.
+ `jump_to!` moves the user back and forth through the history.

The `handle_click!` mutator first checks to make sure that no one has already won at the current step, and that
no one has played in the cell that the user clicked on.  If either of these conditions is true `handle_click!`
returns, no mutation is signaled and nothing changes.

> If we had wanted to return AND signal a state mutation we would use the Ruby `next` keyword instead of `return`.s

To update the board `handle_click!` duplicates the squares; adds the player's token to the cell; makes a new
history with the new squares on the end, and finally updates the value of `@step`.

> We like to use the convention where practical of ending mutator methods with a bang (!) so that readers of the
code are aware that these will change state.

```ruby

class DisplayGame < HyperComponent
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
```

### The Game Display

Now we have a couple of helper methods to build parts of the game display.

+ `moves` creates the list items that allow the user to move back and forth through the history.
+ `status` provides the play state

```ruby
class DisplayGame < HyperComponent
  def moves
    return unless history.length > 1

    history.length.times do |move|
      LI(key: move) { move.zero? ? "Go to game start" : "Go to move ##{move}" }
        .on(:click) { jump_to!(move) }
    end
  end

  def status
    if (winner = current_winner?)
      "Winner: #{winner}"
    else
      "Next player: #{player}"
    end
  end
end
```

And finally our render method which displays the Board and the game info:

```ruby
class DisplayGame < HyperComponent
  render(DIV, class: :game) do
    DIV(class: :game_board) do
      DisplayBoard(board: current)
      .on(:clicked_at, &method(:handle_click!))
    end
    DIV(class: :game_info) do
      DIV { status }
      OL { moves }
    end
  end
end
```

> `&method` turns an instance method into a Proc rather than having to say `{ |id| handle_click(id) }`

### Summary

This small game uses everything covered in the previous sections: HTML Tags, Component Classes, Params, Events and Callbacks, and State.
The project was derived from this React tutorial: https://reactjs.org/tutorial/tutorial.html.
You may want to compare our Ruby code with the React original.


The following sections cover reference materials, and some advanced information.  You may want to skip to the HyperState section which
will use this example to show how state can be encapsulated, extracted and shared resulting in easier to understand and maintain code.
