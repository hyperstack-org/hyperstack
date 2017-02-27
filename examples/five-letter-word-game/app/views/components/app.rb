class Store

  include React::Component
  export_state :your_word
  export_state :their_word

  export_state play_state: :your_turn
  export_state :their_guess
  export_state :your_guess
  export_state your_guesses: []

  def self.game_state
    puts "game_state = '#{your_word}' && '#{their_word}'"
    if your_word && their_word
      :playing
    elsif !your_word
      :picking_word
    else
      :waiting_for_other_player
    end
  end

  def self.im_ready_to_play!(word)
    play_state! :their_turn if their_word
    your_word! word
    ImReadyToPlay.run(word: word)
  end

  ImReadyToPlay.on_dispatch do |params|
    puts "their ready to play.  their word = #{params.word}"
    their_word! params.word
    puts "set their_word to #{their_word}"
  end

  def self.i_guessed!(word)
    your_guess! word
    play_state! :waiting_for_other_player
    MakeGuess.run(guess: word)
  end

  MakeGuess.on_dispatch do |params|
    their_guess! params.guess
    play_state! :waiting_for_number_correct
  end

  def self.give_clue!(correct)
    GiveClue.run(correct: correct)
    play_state! :your_turn
  end

  GiveClue.on_dispatch do |params|
    your_guesses! << [your_guess, params.correct]
    play_state! :waiting_for_other_player
  end

  def self.they_win!
    TheyWin.run
    play_state! :they_win
  end

  TheyWin.on_dispatch do
    play_state! :you_win
  end

  def self.play_again!
    your_word! nil
    their_word! nil
    your_guesses! []
    play_state! :your_turn
  end
end

class App < React::Component::Base
  render(DIV) do
    puts "rendering: game_state = #{Store.game_state}"
    if Store.game_state == :picking_word
      SPAN { 'pick a five letter word' }
      INPUT(id: :word)
      BUTTON { 'play' }.on(:click) { Store.im_ready_to_play! Element['#word'].value }
    elsif Store.game_state == :waiting_for_other_player
      SPAN { 'waiting for the other player...' }
    else
      GameBoard()
    end
  end
end

class GameBoard < React::Component::Base
  render(DIV) do
    puts "rendering game board #{Store.play_state}"
    if Store.play_state == :your_turn
      SPAN { 'guess a word' }
      INPUT(id: :guess)
      BUTTON { 'guess' }
      .on(:click) { Store.i_guessed! Element['#guess'].value }
    elsif [:waiting_for_other_player, :their_turn].include? Store.play_state
      SPAN { 'waiting for the other player...' }
    elsif Store.play_state == :waiting_for_number_correct
      SPAN { "Your word is '#{Store.your_word}'. How many correct in #{Store.their_guess}?" }
      BUTTON { 'thats it!' }
      .on(:click) { Store.they_win! }
      INPUT(id: :no_correct)
      BUTTON { 'correct' }
      .on(:click) { Store.give_clue! Element['#no_correct'].value }
    else
      if Store.play_state == :you_win
        DIV { "YOU WIN :-)" }
      else
        DIV { "they won :-("}
      end
      BUTTON { 'Play Again!' }
      .on(:click) { Store.play_again! }
    end
    Guesses() unless Store.your_guesses.empty?
  end
end

class Guesses < React::Component::Base
  render(OL) do
    Store.your_guesses.each { |guess, no_correct| LI { "#{no_correct} in '#{guess}'" } }
  end
end
