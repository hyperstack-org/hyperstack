# app/hyperloop/components/header.rb
class Header < HyperComponent
  before_mount { @new_todo = Todo.new }
  render(HEADER, class: :header) do                   # add the 'header' class
    H1 { 'todos' }                                    # Add the hero unit.
    EditItem(class: 'new-todo', todo: @new_todo)      # add 'new-todo' class
    .on(:save) { mutate @new_todo = Todo.new }
  end
end
