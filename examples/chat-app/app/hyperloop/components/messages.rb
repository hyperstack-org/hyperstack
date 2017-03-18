class Messages < Hyperloop::Component
  def render
    div.container do # add the bootstrap .container class here.
      MessageStore.all.each do |message|
        Message message: message
      end
    end
  end
end
