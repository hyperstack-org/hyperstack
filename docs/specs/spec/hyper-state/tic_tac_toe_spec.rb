require "spec_helper"

CSS = <<~CSS
  body {
    font: 14px "Century Gothic", Futura, sans-serif;
    margin: 20px;
  }

  ol, ul {
    padding-left: 30px;
  }

  .board_row:after {
    clear: both;
    content: "";
    display: table;
  }

  .status {
    margin-bottom: 10px;
  }

  .square {
    background: #fff;
    border: 1px solid #999;
    float: left;
    font-size: 24px;
    font-weight: bold;
    line-height: 34px;
    height: 34px;
    margin-right: -1px;
    margin-top: -1px;
    padding: 0;
    text-align: center;
    width: 34px;
  }

  .square:focus {
    outline: none;
  }

  .kbd-navigation .square:focus {
    background: #ddd;
  }

  .game {
    display: flex;
    flex-direction: row;
  }

  .game_info {
    margin-left: 20px;
  }
CSS

describe "Tic Tac Toe Game", :js do
  def buttons
    find_all("button", wait: 0.0)
  end

  def squares
    buttons.collect(&:text)
  end

  def lis
    find_all("li", wait: 0.0)
  end

  def history
    lis.collect(&:text)
  end

  def run_the_spec(initial_history)
    binding.pry
    expect(page).to have_content "Next player: X", wait: 0
    expect(history).to eq initial_history
    expect(squares.count).to eq 9
    expect(squares.detect(&:present?)).to be_nil
    buttons[0].click
    expect(page).to have_content "Next player: O", wait: 0
    expect(history).to eq ["Go to game start", "Go to move #1"]
    expect(squares).to eq ["X", "", "", "", "", "", "", "", ""]
    buttons[4].click
    expect(page).to have_content "Next player: X", wait: 0
    expect(history).to eq ["Go to game start", "Go to move #1", "Go to move #2"]
    expect(squares).to eq ["X", "", "", "", "O", "", "", "", ""]
    buttons[2].click
    expect(page).to have_content "Next player: O", wait: 0
    expect(history).to eq ["Go to game start", "Go to move #1", "Go to move #2", "Go to move #3"]
    expect(squares).to eq ["X", "", "X", "", "O", "", "", "", ""]
    buttons[7].click
    expect(page).to have_content "Next player: X", wait: 0
    expect(history).to eq ["Go to game start", "Go to move #1", "Go to move #2", "Go to move #3", "Go to move #4"]
    expect(squares).to eq ["X", "", "X", "", "O", "", "", "O", ""]
    buttons[1].click
    expect(page).to have_content "Winner: X", wait: 0
    lis[3].click
    expect(squares).to eq ["X", "", "X", "", "O", "", "", "", ""]
    expect(history).to eq ["Go to game start", "Go to move #1", "Go to move #2", "Go to move #3", "Go to move #4", "Go to move #5"]
    expect(page).to have_content "Next player: O", wait: 0
    buttons[1].click
    expect(squares).to eq ["X", "O", "X", "", "O", "", "", "", ""]
    expect(history).to eq ["Go to game start", "Go to move #1", "Go to move #2", "Go to move #3", "Go to move #4"]
    expect(page).to have_content "Next player: X", wait: 0
    buttons[3].click
    buttons[7].click
    expect(page).to have_content "Winner: O", wait: 0
    lis[3].click
    buttons[0].click # note in the original JSX implementation this caused a failure
    lis[4].click     # because even though the click is invalid, it still erased the history
    expect(squares).to eq ["X", "O", "X", "", "O", "", "", "", ""]
  end

  it "first translation", skip: "fails see note above at end of run_the_spec" do
    insert_html "<style>\n#{CSS}</style>"
    mount "Game" do
      # function Square(props) {
      #   return (
      #     <button className="square" onClick={props.onClick}>
      #       {props.value}
      #     </button>
      #   );
      # }
      #
      # class Square < HyperComponent
      #   param :value
      #   fires :click
      #   render do
      #     BUTTON(class: :square) { value }
      #     .on(:click) { click! }
      #   end
      # end

      # class Board extends React.Component {
      #   renderSquare(i) {
      #     return (
      #       <Square
      #         value={this.props.squares[i]}
      #         onClick={() => this.props.onClick(i)}
      #       />
      #     );
      #   }#
      #   render() {
      #     return (
      #       <div>
      #         <div className="board-row">
      #           {this.renderSquare(0)}
      #           {this.renderSquare(1)}
      #           {this.renderSquare(2)}
      #         </div>
      #         <div className="board-row">
      #           {this.renderSquare(3)}
      #           {this.renderSquare(4)}
      #           {this.renderSquare(5)}
      #         </div>
      #         <div className="board-row">
      #           {this.renderSquare(6)}
      #           {this.renderSquare(7)}
      #           {this.renderSquare(8)}
      #         </div>
      #       </div>
      #     );
      #   }
      # }

      class Board < HyperComponent
        param :squares
        fires :click

        def draw_square(id)
          BUTTON(class: :square) { squares[id] }
          .on(:click) { click!(id) }
        end

        render(DIV) do
          3.times do |row|
            DIV(class: :board_row) do
              3.times { |col| draw_square(row * 3 + col) }
            end
          end
        end
      end

      # class Game extends React.Component {
      #   constructor(props) {
      #     super(props);
      #     this.state = {
      #       history: [
      #         {
      #           squares: Array(9).fill(null)
      #         }
      #       ],
      #       stepNumber: 0,
      #       xIsNext: true
      #     };
      #   }

      class Game < HyperComponent
        before_mount do
          @history = [{ squares: Array.new(9) }]
          @step = 0
        end

        def player
          @step.even? ? :X : :O
        end

        #   handleClick(i) {
        #     const history = this.state.history.slice(0, this.state.stepNumber + 1);
        #     const current = history[history.length - 1];
        #     const squares = current.squares.slice();
        #     if (calculateWinner(squares) || squares[i]) {
        #       return;
        #     }
        #     squares[i] = this.state.xIsNext ? "X" : "O";
        #     this.setState({
        #       history: history.concat([
        #         {
        #           squares: squares
        #         }
        #       ]),
        #       stepNumber: history.length,
        #       xIsNext: !this.state.xIsNext
        #     });
        #   }

        mutator :handle_click! do |i|
          @history = @history[0..@step]
          current = @history.last
          squares = current[:squares].dup
          return if winner?(squares) || squares[i]

          squares[i] = player
          @history += [{ squares: squares }]
          @step += 1
        end

        #   jumpTo(step) {
        #     this.setState({
        #       stepNumber: step,
        #       xIsNext: (step % 2) === 0
        #     });
        #   }

        mutator(:jump_to!) { |step| @step = step }

        #     const moves = history.map((step, move) => {
        #       const desc = move ?
        #         'Go to move #' + move :
        #         'Go to game start';
        #       return (
        #         <li key={move}>
        #           <button onClick={() => this.jumpTo(move)}>{desc}</button>
        #         </li>
        #       );
        #     });

        def moves
          @history.length.times do |move|
            LI(key: move) do
              move.zero? ? "Go to game start" : "Go to move ##{move}"
            end.on(:click) { jump_to!(move) }
          end
        end

        #     const history = this.state.history;
        #     const current = history[this.state.stepNumber];
        #     const winner = calculateWinner(current.squares);
        #
        #
        #     let status;
        #     if (winner) {
        #       status = "Winner: " + winner;
        #     } else {
        #       status = "Next player: " + (this.state.xIsNext ? "X" : "O");
        #     }

        def current
          @history[@step]
        end

        def status
          if (winner = winner? current[:squares])
            "Winner: #{winner}"
          else
            "Next player: #{player}"
          end
        end

        #     return (
        #       <div className="game">
        #         <div className="game-board">
        #           <Board
        #             squares={current.squares}
        #             onClick={i => this.handleClick(i)}
        #           />
        #         </div>
        #         <div className="game-info">
        #           <div>{status}</div>
        #           <ol>{moves}</ol>
        #         </div>
        #       </div>
        #     );

        render(DIV, class: :game) do
          DIV(class: :game_board) do
            Board(squares: current[:squares])
            .on(:click, &method(:handle_click!))
          end
          DIV(class: :game_info) do
            DIV { status }
            OL { moves }
          end
        end

        # function calculateWinner(squares) {
        #   const lines = [
        #     [0, 1, 2],
        #     [3, 4, 5],
        #     [6, 7, 8],
        #     [0, 3, 6],
        #     [1, 4, 7],
        #     [2, 5, 8],
        #     [0, 4, 8],
        #     [2, 4, 6]
        #   ];
        #   for (let i = 0; i < lines.length; i++) {
        #     const [a, b, c] = lines[i];
        #     if (squares[a] && squares[a] === squares[b] && squares[a] === squares[c]) {
        #       return squares[a];
        #     }
        #   }
        #   return null;
        # }

        LINES = [
          [0, 1, 2],
          [3, 4, 5],
          [6, 7, 8],
          [0, 3, 6],
          [1, 4, 7],
          [2, 5, 8],
          [0, 4, 8],
          [2, 4, 6]
        ]

        def winner?(squares)
          LINES.each do |a, b, c|
            return squares[a] if squares[a] && squares[a] == squares[b] && squares[a] == squares[c]
          end
          false
        end
      end
    end
    run_the_spec(["Go to game start"])
  end

  it "works (even better)" do
    insert_html "<style>\n#{CSS}</style>"
    mount "Game" do
      class Board < HyperComponent
        param :squares
        fires :clicked_at

        def draw_square(id)
          BUTTON(class: :square, id: id) { squares[id] }
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

      class Game < HyperComponent
        before_mount do
          @history = [{ squares: [] }]
          @step = 0
        end

        def player
          @step.even? ? :X : :O
        end

        mutator :handle_click! do |id|
          squares = @history[@step][:squares]
          return if winner?(squares) || squares[id]

          squares = squares.dup
          squares[id] = player
          @history = @history[0..@step] + [{ squares: squares }]
          @step += 1
        end

        mutator(:jump_to!) { |step| @step = step }

        def moves
          return unless @history.length > 1

          @history.length.times do |move|
            LI(key: move) { move.zero? ? "Go to game start" : "Go to move ##{move}" }
              .on(:click) { jump_to!(move) }
          end
        end

        def current
          @history[@step]
        end

        def status
          if (winner = winner? current[:squares])
            "Winner: #{winner}"
          else
            "Next player: #{player}"
          end
        end

        render(DIV, class: :game) do
          DIV(class: :game_board) do
            Board(squares: current[:squares])
            .on(:clicked_at, &method(:handle_click!))
          end
          DIV(class: :game_info) do
            DIV { status }
            OL { moves }
          end
        end

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

        def winner?(board)
          WINNING_COMBOS.each do |a, b, c|
            return board[a] if board[a] && board[a] == board[b] && board[a] == board[c]
          end
          false
        end
      end
    end
    run_the_spec([])
  end

  it "simplified the board  - no hash" do
    insert_html "<style>\n#{CSS}</style>"
    mount "DisplayGame" do
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

      class DisplayGame < HyperComponent
        before_mount do
          @history = [[]]
          @step = 0
        end

        def current
          @history[@step]
        end

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

        def player
          @step.even? ? :X : :O
        end

        state_reader :history

        mutator :handle_click! do |id|
          board = history[@step]
          return if current_winner? || board[id]

          board = board.dup
          board[id] = player
          @history = history[0..@step] + [board]
          @step += 1
        end

        mutator(:jump_to!) { |step| @step = step }

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
    end
    run_the_spec([])
  end

  it "using a store" do
    insert_html "<style>\n#{CSS}</style>"
    mount "DisplayGame" do
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

    end
    run_the_spec([])
  end

  it "using a class level store" do
    insert_html "<style>\n#{CSS}</style>"
    mount "DisplayGame" do
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
    end
    run_the_spec([])
  end
end
