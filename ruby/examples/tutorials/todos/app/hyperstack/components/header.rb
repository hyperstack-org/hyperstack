# app/hyperstack/components/header.
class Header < HyperComponent
  before_mount { @new_todo = Todo.new }
  render(HEADER, class: :header) do
    H1 { 'todos' }
    EditItem(class: 'new-todo', todo: @new_todo)
    .on(:saved) { mutate @new_todo = Todo.new }
  end
end
