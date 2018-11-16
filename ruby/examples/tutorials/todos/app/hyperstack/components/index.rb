# app/hyperloop/components/index.rb
class Index < HyperComponent
  include Hyperstack::Router::Helpers
  render(SECTION, class: :main) do
    UL(class: 'todo-list') do
      Todo.send(match.params[:scope]).each do |todo|
        TodoItem(todo: todo)
      end
    end
  end
end
