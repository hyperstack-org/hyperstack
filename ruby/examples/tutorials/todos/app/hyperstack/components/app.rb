# app/hyperloop/components/app.rb
class App < HyperComponent
  include Hyperstack::Router
  history :browser
  route do # note instead of render we use the route method
    SECTION(class: 'todo-app') do
      Header()
      Route('/', exact: true) { Redirect('/all') }
      Route('/:scope', mounts: Index)
      Footer() unless Todo.count.zero?
    end
  end
end
