

### Revisiting the Tic Tac Toe Game

The easiest way to understand HyperState is by example.  If you you did not see the Tic-Tac-Toe example, then **[please review it now](client-dsl/interlude-tic-tac-toe.md)**, as we are going to use this to demonstrate how to use the `Hyperstack::State::Observable` module.

In our original Tic-Tac-Toe implementation the state of the game was stored in the `DisplayGame` component.  State was updated by
"bubbling up" events from lower level components up to `DisplayGame` where the event handler updated the state.

This is a nice simple approach but suffers from two issues:
+ Each level of lower level components must be responsible for bubbling up the events to the higher component.
+ The `DisplayGame` component is responsible for both managing state and displaying the game.

As our applications become larger we will want a way to keep each component's interface isolated and not dependent on the overall
architecture, and to insure good separation of concerns.  

The `Hyperstack::State::Observable` module allows us to put the game's state into a separate class which can be accessed from any
component:  No more need to bubble up events, and no more cluttering up our `DisplayGame` component with state management
and details of the game's data structure.

Here is the game state and associated methods moved out of the `DisplayGame` component into its own class:

```ruby
class Game
  include Hyperstack::State::Observable

  def initialize
    @history = [[]]
    @step = 0
  end

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
```
Let's go over the each of the differences from the code that was in the `DisplayGame` component.

```ruby
class Game
  include Hyperstack::State::Observable
```

`Game` is now in its own class and includes `Hyperstack::State::Observable`. This adds a number of methods to `Game` that allows our class to become
a *reactive store*.  When `Game` interacts with other stores and components they will be updated as the state of  `Game` changes.

```ruby
  def initialize
    @history = [[]]
    @step = 0
  end
```

In the original implementation we initialized the two state variables `@history` and `@step` in the `before_mount` callback. The same initialization
is now in the `initialize` method which will be called when a new instance of the game is created.  This will still be done in the  `DisplayGame`
`before_mount` callback (see below.)

```ruby
  observer :player do
    @step.even? ? :X : :O
  end

  observer :current do
    @history[@step]
  end
```

In the original implementation we had instance methods `player` and `current`.  Now that `Game` is a separate class we define these
methods using `observer`.

The `observer` method creates a method that is the inverse of `mutator`.  While `mutate` (and `mutator`) indicate that state has
been changed `observe` and `observer` indicate that state has been accessed outside the class.  

```ruby
  attr_reader :history
```

Just as we have `mutate`, `mutator`, and `state_writer`, we have `observe`, `observer`, and `state_reader`.

```ruby
  WINNING_COMBOS = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

  def current_winner?
    WINNING_COMBOS.each do |a, b, c|
      return current[a] if current[a] && current[a] == current[b] && current[a] == current[c]
    end
    false
  end
```

We don't need any changes to `current_winner?`.  It accesses the internal state through the `current` method
so there is no need to explicitly make `current_winner?` an observer (but we could, without affecting anything.)

```ruby
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

Finally we need no changes to the `handle_click!` and `jump_to!` mutators either.

#### The Updated DisplayGame Component

```ruby
class DisplayGame < HyperComponent
  before_mount { @game = Game.new }
  def moves
    return unless @game.history.length > 1

    @game.history.length.times do |move|
      LI(key: move) { move.zero? ? "Go to game start" : "Go to move ##{move}" }
        .on(:click) { @game.jump_to!(move) }
    end
  end

  def status
    if (winner = @game.current_winner?)
      "Winner: #{winner}"
    else
      "Next player: #{@game.player}"
    end
  end

  render(DIV, class: :game) do
    DIV(class: :game_board) do
      DisplayCurrentBoard(game: @game)
    end
    DIV(class: :game_info) do
      DIV { status }
      OL { moves }
    end
  end
end
```

The `DisplayGame` `before_mount` callback is still responsible for initializing the game, but it no longer needs to be aware of
the internals of the game's state.  It simply calls `Game.new` and stores the result in the `@game` instance variable. For the rest
of the component's code we call the appropriate method on `@game`.

We will need to pass the entire game to `DisplayBoard` (we will see why shortly) so we will rename it to `DisplayCurrentBoard`.

As we will see `DisplayCurrentBoard` will be responsible for directly notifying the game that a user has clicked, so we do not
need to handle any events coming back from `DisplayCurrentBoard`.

#### The DisplayCurrentBoard Component

```ruby
class DisplayCurrentBoard < HyperComponent
  param :game

  def draw_square(id)
    BUTTON(class: :square, id: id) { game.current[id] }
    .on(:click) { game.handle_click!(id) }
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

The `DisplayCurrentBoard` component receives the entire game, and it will access the current board, using the
`current` method, and will directly notify the game when a user clicks using the `handle_click!` method.

By having `DisplayCurrentBoard` directly deal with user actions, we simplify both components as they do not have to
communicate back upwards via events.  Instead we communicate through the central game store.

### The Flux Loop

Rather than sending params down to lower level components, and having the components bubble up events, we have created a *Flux Loop*.
The `Game` store holds the state, the top level component reads the state and sends it down to lower level components, those
components update the `Game` state causing the top level component to re-rerender.  

This structure greatly simplifies the structure and understanding of our components, and keeps each component functionally isolated.

Furthermore algorithms such as `current_winner?` now are neatly abstracted out into their own class.

### Classes and Instances

If we are sure we will only want one game board, we could define `Game` with class methods like this:

```ruby
class Game
  include Hyperstack::State::Observable

  class << self
    def initialize
      @history = [[]]
      @step = 0
    end

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

Now instead of creating an instance and passing it around we
call the class level methods on `Game` throughout.

The `Hyperstack::State::Observable` module will call any class level `initialize` methods in the class or subclasses
before the first component mounts.

Note that with this approach we can go back to passing just the current board to `DisplayBoard` as `DisplayBoard` can
directly access `Game.handle_click!` since there is only one game.

### Thinking About Stores

To summarize: a store is simply a Ruby object or class that using the `observe` and `mutate` methods marks when its internal data
has been observed by some other class, or when its internal data has changed.

When components render they observe stores throughout the system, and when those stores mutate the components will rerender.

You as the programmer need only to remember that public methods that read *internal* state must at some point
during their execution declare this using `observe`, `observer`,
`state_reader` or `state_accessor` methods.  Likewise a method that changes *internal* state must declare this using `mutate`, `mutator`, `state_writer` or `state_accessor` methods.

If your store's methods access other stores, you do not need worry about their state, only your own.  On the other hand keep in mind
that the built in Ruby Array and Hash classes are **not** stores, so when you modify or read an Array or a Hash its up to you to use
the appropriate `mutate` or `observe` method.

### Stores and Parameters

Typically in a large system you will have one or more central stores, and what you end up passing as parameters are either instances of those stores, or some other kind of index into the store.  If there is only one store (as in the case of our Game), you
need not pass any parameters at all.

We can rewrite the previous iteration of `DisplayBoard` to demonstrate this:

```ruby
class DisplaySquare
  param :id
  render
    BUTTON(class: :square, id: id) { Game.current[id] }
    .on(:click) { Game.handle_click(id) }
  end
end

class DisplayBoard < HyperComponent
  render(DIV) do
    (0..6).step(3) do |row|
      DIV(class: :board_row) do
        (row..row + 2).each { |id| DisplaySquare(id: id) }
      end
    end
  end
end
```

Here `DisplayBoard` no longer takes any parameter (and could be renamed again to `DisplayCurrentBoard`) and now a new component -
`DisplaySquare` - takes the id of the square to display, but the game or the current board are never passed as parameters;
there is no need to as they are implicit.

Whether to pass (or not pass) a store class, an instance of a store, or some other index into the store is a design decision that depends on
lots of factors, mainly how you see your application evolving over time.

### Summary of Methods

All the observable methods can be used either at the class or instance level.

#### Observing State: `observe, observer, state_reader`

The `observe` method takes any number of arguments and/or a block. The last argument evaluated or the value of the block is returned.

The arguments and block are evaluated then the object's state will be *observed*.  

If the block exits with a return or break, the state will **not** be observed.

```ruby
# evaluate and return a value
observe @history[@step]

# evaluate a block and return its value
observe do
  @history[@step]
end
```

The `observer` method defines a new method with an implicit observe:

```ruby
observer :foo do |x, y, z|
  ...
end
```
is equivilent to
```ruby
def foo(x, y, z)
  observe do
    ...
  end
end
```

Again if the block exits with a `return` or `break` the state will **not** be observed.

The `state_reader` method declares one or more state accessors with an implicit state observation:

```ruby
state_reader :bar, :baz
```
is equivilent to
```ruby
def bar
  observe @bar
end
def baz
  observe @baz
end
```

#### Mutating State: `mutate, mutator, state_writer, toggle`

The `mutate` method takes any number of arguments and/or a block. The last argument evaluated or the value of the block is returned.

The arguments and block are evaluated then the object's state will be *mutated*.  

If the block exits with a return or break, the state will **not** be mutated.

```ruby
# evaluate and return a value
mutate @history[@step]

# evaluate a block and return its value
mutate do
  @history[@step]
end
```

The `mutator` method defines a new method with an implicit mutate:

```ruby
mutator :foo do |x, y, z|
  ...
end
```
is equivilent to
```ruby
def foo(x, y, z)
  mutate do
    ...
  end
end
```

Again if the block exits with a `return` or `break` the state will **not** be mutated.

The `state_writer` method declares one or more state accessors with an implicit state mutation:

```ruby
state_reader :bar, :baz
```
is equivilent to
```ruby
def bar=(x)
  mutate @bar = x
end
def baz=(x)
  observe @baz = x
end
```

The `toggle` method reverses the polarity of a instance variable:

```ruby
toggle(:foo)
```
is equivilent to
```ruby
mutate @foo = !@foo
```

#### The `state_accessor` Method

Combines `state_reader` and `state_writer` methods.

```ruby
state_accessor :foo, :bar
```
is equivilent to
```ruby
state_reader :foo, :bar
state_writer :foo, :bar
```

### Components and Stores

The standard `HyperComponent` base class includes `Hyperstack::State::Observable` so any `HyperComponent` has access to
all of the above methods.  A component also always **observes itself** so you never need to use `observe` within
a component **unless** the state will be accessed outside the component.   However once you start doing that you
would be better off to move the state into a separate store.

> In addition components also act as the **Observers** in the system.  What this means is
that the current component that is running its render method is recording all stores that call `observe`, when
a store mutates, then all the components that recorded observations will be rerendered.
