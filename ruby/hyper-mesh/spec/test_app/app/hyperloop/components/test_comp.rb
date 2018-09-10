class TestComp < Hyperloop::Component
  render(DIV) do
    if Messages.all.count == 0
      DIV { "No Messages" }
    else
      UL do
        Messages.all.each do |message|
          LI { message }
        end
      end
    end
    DIV do
      if TodoItem.all.count == 0
        DIV { "No Todos" }
      else
        UL do
          TodoItem.each do |todo|
            LI { "#{todo.title}" }
          end
        end
      end
    end.while_loading { 'loading...' }
  end
end
