# app/hyperloop/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI, class: 'todo-item') do
    if @editing
      EditItem(class: :edit, todo: @Todo)
      .on(:save, :cancel) { mutate @editing = false }
    else
      INPUT(type: :checkbox, class: :toggle, checked: @Todo.completed)
      .on(:change) { @Todo.update(completed: !@Todo.completed) }
      LABEL { @Todo.title }
      .on(:double_click) { mutate @editing = true }
      A(class: :destroy)
      .on(:click) { @Todo.destroy }
    end
  end
end
