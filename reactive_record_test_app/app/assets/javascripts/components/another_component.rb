require 'user'
class AnotherComponent
  
  include React::Component
  
  export_component
  
  required_param :user, type: User
  
  backtrace :on
  
  def render
    div do
      "#{user.name}'s todos:".br
      ul do
        broken!
        user.todo_items.each do |todo|
          li { TodoItemComponent(todo: todo) }
        end
      end
    end
  end
  
end