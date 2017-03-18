module Operations
  # encapsulates our "messages store" server side
  # the params and dispatcher will be inherited
  class ServerBase < Hyperloop::ServerOp
    param :acting_user, nils: true
    param :user_name
    dispatch_to { Hyperloop::Application }

    def messages
      Rails.cache.fetch('messages') { [] }
    end

    def add_message
      params.message = {
        message: params.message,
        time: Time.now,
        from: params.user_name
      }
      Rails.cache.write('messages', messages << params.message)
    end
  end

  # get all the messages
  class GetMessages < ServerBase
    outbound :messages

    step { params.messages = messages }

    def self.deserialize_dispatch(messages)
      # convert the time string back to time
      messages[:messages].each do |message|
        message[:time] = Time.parse(message[:time])
      end
      messages
    end
  end

  # send a message to everybody
  class Send < ServerBase
    param :message

    step :add_message

    def self.deserialize_dispatch(message)
      # convert time strings back to time
      message[:message][:time] = Time.parse(message[:message][:time])
      message
    end
  end

  # client side only: registers user_name and then gets the messages
  class Join < Hyperloop::Operation
    param :user_name
    step GetMessages
  end
end
