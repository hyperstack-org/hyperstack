require 'operations/ops'
class Store < Hyperloop::Store
  class << self

    def my_guesses
      state.guesses[my_id]
    end

    def my_word
      state.word[my_id]
    end

    state :current_guess, reader: true

    def my_id
      Hyperloop::Application.acting_user_id
    end

    def game_state
      if !my_word
        :picking_word
      elsif !state.word[state.their_id]
        :waiting_for_other_player
      elsif state.winner
        :"#{state.winner == my_id ? 'you' : 'they'}_win"
      elsif state.current_guess
        :"waiting_for_a_clue_from_#{state.current_guesser == my_id ? 'them' : 'you'}"
      else
        :"waiting_for_#{state.current_guesser == my_id ? 'your' : 'their'}_guess"
      end
    end

    def game_over?
      game_state =~ /_win$/
    end

    def setup
      mutate.guesses Hash.new { |h, k| h[k] = [] }
      mutate.winner nil
      mutate.word Hash.new
      mutate.current_guesser nil
      mutate.current_guess nil
      mutate.their_id nil
      Ops::Join.run
    end
  end

  receives Ops::Join do |params|
    puts "receiving Ops::Join(#{params})"
    mutate.their_id params.sender != my_id ? params.sender : params.other_player
    Ops::ReadyToPlay.run(word: state.word[my_id]) if state.word[my_id]
  end

  receives Ops::ReadyToPlay do |params|
    puts "receiving READYTOPLAY #{params.word}"
    mutate.current_guesser params.sender unless state.current_guesser
    mutate.word[params.sender] = params.word
  end

  receives Ops::Guess do |params|
    puts "receiving guess #{params}"
    mutate.current_guess params.word
  end

  receives Ops::Clue do |params|
    puts "receving CLUE #{params}"
    mutate.guesses[params.other_player] << [state.current_guess, params.correct]
    puts "updated guesses"
    mutate.current_guess nil
    puts "updated current guess to nil"
    mutate.current_guesser params.sender
    puts "switched to other guys turn"
  end

  receives Ops::YouWin do |params|
    mutate.winner params.other_player
    mutate.message params.message
  end

  receives Ops::PlayAgain, :setup
  receives Hyperloop::Application::Boot, :setup
end
