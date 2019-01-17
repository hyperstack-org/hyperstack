# app/hyperstack/components/footer.rb
class Footer < HyperComponent
  include Hyperstack::Router::Helpers
  def link_item(path)
    LI { NavLink("/#{path}", active_class: :selected) { path.camelize } }
  end
  render(DIV, class: :footer) do
    SPAN(class: 'todo-count') { "#{pluralize(Todo.active.count, 'item')} left" }
    UL(class: :filters) do
      link_item(:all)
      link_item(:active)
      link_item(:completed)
    end
  end
end
