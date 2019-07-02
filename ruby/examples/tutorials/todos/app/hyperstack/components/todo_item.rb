# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI, class: 'todo-item') do
    if @editing
      EditItem(class: :edit, todo: todo)
      .on(:saved, :cancel) { mutate @editing = false }
    else
      INPUT(type: :checkbox, class: :toggle, checked: todo.completed)
      .on(:change) { todo.update(completed: !@Todo.completed) }
      LABEL { todo.title }
      .on(:double_click) { mutate @editing = true }
      A(class: :destroy)
      .on(:click) { todo.destroy }
    end
  end
end
