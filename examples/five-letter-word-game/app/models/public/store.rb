class Store
  class BaseOp < Hyperloop::ServerOp
    param :acting_user, nils: true
    param :sender
    dispatch_to { Application }
    if RUBY_ENGINE == 'opal'
      def self.id
        @@id ||= rand(10000000)
      end

      def self.run(params = {})
        params[:sender] = id
        super
      end

      def self.dispatch_from_server(params)
        super if params[:sender] != BaseOp.id
      end
    end
  end

  class ImReadyToPlay < BaseOp
    param :word
  end

  class MakeGuess < BaseOp
    param :guess
  end

  class GiveClue < BaseOp
    param :correct
  end

  class TheyWin < BaseOp
  end
end
