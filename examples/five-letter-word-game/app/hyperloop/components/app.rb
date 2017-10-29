require 'stores/store'
class App < React::Component::Base

  render(DIV) do
    puts "rendering: game_state = #{Store.game_state}"
    puts "their_id: #{Store.state.their_id}, my_id: #{Store.my_id} words: #{Store.state.word}"
    DIV { Store.message } if Store.message
    send Store.game_state # for each game_state we have a method below...
    Guesses.run() unless Store.my_guesses.empty?
  end

  def initializing
    SPAN { '...' }
  end

  def picking_word
    InputWord label: 'pick a five letter word', button: 'play', operation: Ops::ReadyToPlay
  end

  def waiting_for_other_player
    SPAN { "Your word is: #{Store.my_word}. Waiting for the other player to pick their word..." }
    BUTTON { 'Change Your Word' }.on(:click) { Ops::ChangeWord.run() }
  end

  def waiting_for_your_guess
    InputWord label: 'Guess a word', button: 'guess', operation: Ops::Guess
  end

  def waiting_for_their_guess
    SPAN { 'waiting for the other player to guess a word...' }
  end

  def waiting_for_a_clue_from_them
    SPAN { 'waiting for the other player to give you the number correct...' }
  end

  def waiting_for_a_clue_from_you
    SPAN { "Your word is '#{Store.my_word}'." }
    SELECT do
      OPTION(selected: true,  disabled: true) { "How many correct in '#{Store.current_guess}'?" }
      (0..5).each { |count| OPTION(value: count) { count.to_s } }
      OPTION(value: :win) { "#{Store.current_guess} is correct!"}
    end.on(:change) do |e|
      if e.target.value == :win
        Ops::YouWin.run()
      else
        Ops::Clue.run their_word: Store.current_guess, my_word: Store.my_word, correct: e.target.value
      end
    end
  end

  def you_win
    DIV { "YOU WIN :-)" }
    play_again
  end

  def they_win
    DIV { "they won :-("}
    play_again
  end

  def play_again
    BUTTON { 'Play Again!' }.on(:click) { Ops::PlayAgain.run() }
  end
end
