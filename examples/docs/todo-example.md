TODO not sure where this example should go?

Lets look at part of a very simple Todo application with one model:

```ruby
# app/models/public/todo.rb  <- public models are accessible on the client
class Todo < ActiveRecord::Base
  scope :active ->() { where(completed: true) }
  scope :complete ->() { where(completed: false) }
end
```

To show our Todo's we might have a very simple app like this:

```ruby
# app/views/components/app.rb
class App < Hyperloop::Component

  define_state scope: :active        
  define_state new_todo: Todo.new

  def todos  # display our list of todos
    ul do
      Todo.send(state.scope).each do |todo|
        li do
          status(todo); todo.title.span; delete_button(todo)
        end
      end
    end
  end

  def status(todo) # display / change the status
    checkbox(type: :checkbox, checked: todo.completed)
    .on(:click) do
      todo.completed = !todo.completed
      todo.save
    end
  end

  def delete_button(todo) # delete a todo
    button { "delete!" }.on(:click) { todo.destroy }
  end

  def save_new_todo  # save a new todo
    state.new_todo.save
    state.new_todo! Todo.new
  end

  def link(to) # display a link to a scope
    button { to }.on(:click) { state.scope! to }
  end

  render do # render everything
    div do
      todos
      input(value: state.new_todo.title)
      .on(:change) { |e| state.new_todo.title = e.target.value }
      .on(:key_down) { |e| save_new_todo if e.key_code == 13 }
      div { link(:all); link(:active); link(:complete) }
    end
  end
end
```

Finally we will need a controller:

```ruby
class HomeController < ApplicationController
  def app
    render_component
  end
end
```

Except for configuration that is our complete App.  When the page loads it will show all the todos currently in the database.  As the user changes the state of the Todos (or adds more) the changes will be persisted via the Todo model.

In order to have the changes on one browser be synchronized across all browsers we have to set up some *policies* to define the desired behavior.  Here is a very simple policy without any protection:

```ruby
#app/policies/application_policy.rb
class ApplicationPolicy
  always_allow_connection  # any browser may connect
  regulate_all_broadcasts &:send_all # send all changes from all models
  allow_change(to: :all, on: [:create, :update, :destroy])
end
```

That is it!

Lets walk through what happens users interact with the system.

When the page first renders (on the server) our `App` component executes (on the server) and renders the initial view.  This is no different from the normal rendering cycle of any rails view, the only difference is we are using `Ruby` as our templating language.

Compare the lines:
```ruby
ul do
  Todo.send(state.scope).each do |todo|
    li do
      status(todo); todo.title.span; delete_button(todo)
    end
  end
end
```
to the equivilent html.erb file:
```html
<ul>
  <% Todo.send(@scope).each do |todo| %>
    <li>
      ...
    </li>
  <% end %>
</ul>
```
The only difference is your brain doesn't hurt from all the syntactic context switching.

So the server builds a pile of html and dumps it the browser as normal, but once on the browser we have the exact same ruby code running their as well.  It will automatically add all of event handlers (`on(:click), on(:change)`, etc), and as the events occur the underlying react.js system will cause portions of our code to rerender.

Also during the client load any connections allowed to the browser will be established so that changes in the server database made by other sources will get broadcast to us.
