module Ops
  class Base < Hyperloop::ServerOp
    # base class for all the other server side operations
    # All operations take the acting_user and add outbound
    # sender and other_player params which are just the ids.

    param :acting_user
    outbound :sender
    outbound :other_player

    # partners holds a hash of partner pairs i.e. x => y, y => x
    # if z is waiting for a partner the hash holds z => nil

    def self.partners
      @partners ||= {}
    end

    # find the waiting player

    def waiting_player
      Base.partners.key(nil)
    end

    # for a given acting user find the partner

    def other_player
      Base.partners[params.acting_user]
    end

    # either attach the acting_user to the waiting player
    # of if there is no waiting player, make acting_user the waiting player

    def partner_up
      if waiting_player
        params.other_player = waiting_player.id
        Base.partners[params.acting_user] = waiting_player
        Base.partners[waiting_player] = params.acting_user
      elsif !Base.partners.key?(params.acting_user)
        Base.partners[params.acting_user] = nil
      end
    end

    # unhook partners at game end

    def unpartner
      Base.partners.delete other_player
      Base.partners.delete params.acting_user
    end

    # check words for validity

    def five_unique_letters
      return true if params.word.downcase.split('').uniq.join =~ /^[a-zA-Z]{5}$/
      abort "words and guesses must have 5 different letters"
    end

    # check clue for accuracy

    def check_clue
      params.true_count =
        (Set.new(params.their_word.downcase.split('')) & params.my_word.downcase.split('')).count
    end

    # grab the ids from the two players
    step { params.other_player = other_player && other_player.id }
    step { params.sender = params.acting_user.id }
    # save the value of other player in case the subclass changes it
    step { @current_other_player = other_player }

    # dispatch to both players.  The other player may be set or removed during
    # the operation, so we dispatch to the before and after values
    dispatch_to { [params.acting_user, other_player, @current_other_player] }
  end

  class ReadyToPlay < Base
    param :word, type: String
    validate :five_unique_letters
  end

  class ChangeWord < Base
  end

  class Guess < Base
    param :word
    validate :five_unique_letters
  end

  class Clue < Base
    param :their_word
    param :my_word
    param :correct, type: Integer, min: 0, max: 5
    outbound :true_count
    step :check_clue
  end

  class YouWin < Base
    param message: nil
    step :unpartner
  end

  class Join < Base
    step :partner_up
  end

  class ShareState < Base
    param :guesses
    param :word
    param :current_guesser, nils: true
    param :current_guess,   nils: true
    param :message
  end

  class PlayAgain < Hyperloop::Operation
  end
end
