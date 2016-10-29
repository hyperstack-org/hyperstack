require 'hyper-react'

class TodoItemComponent

  include React::Component

  required_param :todo
  backtrace :on

  def render
    div do
      "Title: #{todo.title}".br; "Description #{todo.description}".br; "User #{todo.user.name}"
    end
  end

end
