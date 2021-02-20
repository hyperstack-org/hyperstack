# HyperSpec

## Adding client side testing to RSpec

The `hyper-spec` gem supports the Hyperstack goals of programmer productivity and seamless web development by allowing testing to be done with minimal concern for the client-server interface.

The `hyper-spec` gem adds functionality to the `rspec`, `capybara`, `timecop` and `pry` gems allowing you to do the following:

+ write component and integration tests using the rspec syntax and helpers
+ write specs that run on both the client and server
+ evaluate client side ruby expressions from within specs and while using `pry`
+ share data between the client and server within your specs
+ control and synchronize time on the client and the server

HyperSpec can be used standalone, but if used as part of a Hyperstack application it allows straight forward testing of Hyperstack Components and your ActiveRecord Models.

So for example here is part of a simple unit test of a TodoIndex component:

```ruby
it "will update the TodoIndex", js: true do
  # mounts the TodoIndex component (client side)
  mount 'TodoIndex'
  # Todo is an ActiveRecord Model
  # create a new Todo on the server (we could use FactoryBot of course)
  todo_1 = Todo.create(title: 'this todo created on the server')
  # verify that UI got updated
  expect(find('.ToDoItem-Text').text).to eq todo_1.title
  # verify that the count of Todos on the client side DB matches the server
  expect { Todo.count }.on_client_to eq Todo.count
  # now create another Todo on the client
  new_todo_title = 'this todo created on the client'
  # note that local variables are copied from the server to the client
  on_client { Todo.create(title: new_todo_title) }
  # the Todo should now be reflected on the server
  expect(Todo.last.title).to eq new_todo_title
end
```

When using HyperSpec all the specs execute on the server side, but they may also interrogate the state of the UI as well as the state
of any of the client side objects.  The specs can execute any valid Ruby code client side to create new test objects as well as do
white box testing.  This keeps the logic of your specs in one place.
