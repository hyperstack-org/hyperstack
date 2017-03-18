class App < Hyperloop::Component
  def render
    div do
      Nav()
      if MessageStore.online?
        Messages()
        InputBox()
      end
    end
  end
end
