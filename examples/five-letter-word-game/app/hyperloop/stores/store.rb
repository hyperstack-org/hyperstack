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

    def message
      state.message[my_id]
    end

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
      mutate.guesses Hash.new { |guesses, player| guesses[player] = [] }
      mutate.winner nil
      mutate.word Hash.new
      mutate.current_guesser nil
      mutate.current_guess nil
      mutate.their_id nil
      mutate.message Hash.new
      Ops::Join.run if Hyperloop.on_client?
    end
  end

  receives Ops::Join do |params|
    puts "receiving Ops::Join.run(#{params})"
    if state.their_id && params.sender != my_id
      Ops::ShareState.run(
        guesses: state.guesses,
        word: state.word,
        current_guesser: state.current_guesser,
        current_guess: state.current_guess,
        message: state.message
      )
    else
      mutate.their_id params.sender != my_id ? params.sender : params.other_player
      Ops::ReadyToPlay.run(word: state.word[my_id]) if state.word[my_id]
    end
  end

  receives Ops::ShareState do |params|
    puts "receiving Ops::ShareState.run(#{params})"
    if params.sender != my_id
      params.guesses.each { |player, guesses| mutate.guesses[player] = guesses }
      mutate.word params.word
      mutate.current_guesser params.current_guesser
      mutate.current_guess params.current_guess
      mutate.message params.message
    end
  end

  receives Ops::ReadyToPlay do |params|
    puts "receiving Ops::ReadyToPlay.run(#{params})"
    mutate.current_guesser params.sender unless state.current_guesser
    mutate.word[params.sender] = params.word
  end

  receives Ops::ChangeWord do |params|
    puts "receiving Ops::ChangeWord.run(#{params})"
    mutate.word[params.sender] = nil
    mutate.current_guesser nil if params.sender == state.current_guesser
  end

  receives Ops::Guess do |params|
    puts "receiving Ops::Guess.run(#{params})"
    mutate.current_guess params.word
    mutate.message({})
  end

  receives Ops::Clue do |params|
    puts "receiving Ops::Clue.run(#{params})"
    mutate.guesses[params.other_player] << [state.current_guess, params.true_count]
    if params.true_count == params.correct
      mutate.current_guesser params.sender
    else
      mutate.message[params.sender] =
        "That was a bogus clue.  There are #{params.true_count} correct in #{current_guess}.  They get a free guess!"
      mutate.message[params.other_player] =
        "They tried to give you a bogus clue!  There are #{params.true_count} correct in #{current_guess}.  Have a free turn!"
    end
    mutate.current_guess nil
  end

  receives Ops::YouWin do |params|
    puts "receiving Ops::YouWin.run(#{params})"
    mutate.winner params.other_player
    mutate.message[my_id] = params.message
  end

  receives Ops::PlayAgain, :setup
  receives Hyperloop::Application::Boot, :setup
end
