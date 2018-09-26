
# TodoMVC Tutorial (Rails 5.2.0)

### Prerequisites

{ [Ruby On Rails](http://rubyonrails.org/) }

### The Goals of this Tutorial

In this tutorial you will build the classic [TodoMVC](http://todomvc.com) application using Hyperloop

The finished application will

1. have the ability to add and edit todos;
2. be able change the complete/incomplete state;
3. filter the list of displayed todos to show all, complete, or incomplete (active) todos;
4. have html5 history so that as the filter changes so does the URL;
6. have server side persistence;
7. and synchronization across multiple browser windows.

You will write less than 100 lines of code, and the tutorial should take about 1-2 hours to complete.

You can find the older application source code here:


### Skills required

Working knowledge of Rails and Hyperloop required

## TUTORIAL

### Chapter 1: Setting Things Up

Create a new rails application
```ruby
  rails _5.2.0_ new hyperloop_todo
```
_5.2.0_  will insure you are creating a rails 5.2 appear (tested with 5.0 and 5.1)

Add Hyperloop to your Gemfile

Until our official release, add the following to your Gemfile:
```ruby
  ...
  # lap0 will use the latest release candidate
  gem 'hyperloop', '~> 1.0.0.lap0', git: 'https://github.com/ruby-hyperloop/hyperloop.git', branch: 'edge'
  gem 'hyperloop-config', '~> 1.0.0.lap0', git: 'https://github.com/ruby-hyperloop/hyperloop-config.git', branch: 'edge'
  ...
```

then
```ruby
  bundle install
```

Once the Hyperloop Gem and all its dependencies have been installed, it's time to run the hyperloop install generator.
```ruby
  rails g hyperloop:install
```

The generator creates the hyperloop structure inside the /app directory :
```ruby
  /app/hyperloop/
  /app/hyperloop/components
  /app/hyperloop/models
  /app/hyperloop/operations
  /app/hyperloop/stores
```

And updates your app/assets/javascripts/application.js file adding these lines:
```ruby
  //= require hyperloop-loader
  Opal.OpalHotReloader.$listen() // optional (port, false, poll_seconds) i.e. (8081, false, 1)
```

To be sure everything is setting up correctly, check your app/assets/javascripts/application.js:
```ruby
  ...
  //= require rails-ujs
  //= require activestorage
  //= require turbolinks
  //= require_tree .
  //= require hyperloop-loader
  Opal.OpalHotReloader.$listen() // optional (port, false, poll_seconds) i.e. (8081, false, 1)
```

Run foreman
```ruby
  $ foreman start
```

Navigate to the given location and you should see the word **App** displayed on the page.

### Chapter 2:  Hyperloop Models are Rails Models

We are going to add our Todo Model, and discover that Hyperloop models are in fact Rails models.
+ You can access the your rails models on the client using the same syntax you use on the server.
+ Changes on the client are mirrored on the server.
+ Changes to models on the server are synchronized with all participating browsers.
+ Data access is is protected by a robust *policy* mechanism.

>*A Rails ActiveRecord Model is a Ruby class that is backed by a database table.  In this example we will have one model class called `Todo`.  When manipulating models, Rails automatically generates the necessary SQL code for you.  So when `Todo.all` is evaluated Rails generates the appropriate SQL
and turns the result of the query into appropriate Ruby data structures.*

>*Hyperloop Models are extensions of ActiveRecord Models that synchronize the data between the client and server
automatically for you.  So now `Todo.all` can be evaluated on the server or the client.*

Okay lets see it in action:

1. **Add the Todo Model:**  
  In a new terminal window run **on a single line**:   
  ```ruby
    bundle exec rails g model Todo title:string completed:boolean priority:integer
  ```

  This runs a Rails *generator* which will create the skeleton Todo model class, and create a *migration* which will
  add the necessary tables and columns to the database.  

  **VERY IMPORTANT!** Now look in the db/migrate/ directory, and edit the migration file you have just created. The file will be titled with a long string of numbers then "create_todos" at the end. Change the line creating the completed boolean field so that it looks like this:
  ```ruby  
    ...
    t.boolean :completed, null: false, default: false
    ...
  ```  
  For details on 'why' see [this blog post.](https://robots.thoughtbot.com/avoid-the-threestate-boolean-problem)
  Basically this insures `completed` is treated as a true boolean, and will avoid having to check between `false` and `null` later on.   

  Now run
  ```ruby
    bundle exec rails db:migrate
  ```
  which will create the table.

2. **Make Some Models Public:**  
  *Move* `models/todo.rb` and `models/application_record.rb` to `hyperloop/models`.  

   This will make the model accessible on the clients *and the server*, subject to any data access policies.  

   *Note: The hyperloop installer adds a policy that gives full permission to all clients but only in development and test modes.  Have a look at `app/policies/application_policy` if you are interested.*

3. **Try It**
  Change your `App` component's render method to:  
  ```ruby
    # app/hyperloop/components/app.rb
    class App < Hyperloop::Component
     render(DIV) do
       "Number of Todos: #{Todo.count}"
     end
    end
  ```  

   **Reload the Page**
   You will now see *Number of Todos: 0* displayed.  *You must reload the page as you have changed the class of App from `Router` to `Component`*

   Now start a rails console
   ```ruby
    bundle exec rails c
   ```
   and type:  
   ```ruby
     Todo.create(title: 'my first todo')
   ```  
   This is telling the server to create a new todo, which will update your hyperloop application, and you will see the count change to 1!   

   Try it again:  
   ```ruby
     Todo.create(title: 'my second todo')
   ```  
   and you will see the count change to 2!   

Are we having fun yet?  I hope so!  As you can see Hyperloop is synchronizing the Todo model between the client and server.  As the state of the database changes, HyperReact buzzes around updating whatever parts of the DOM were dependent on that data (in this case the count of Todos).

Notice that we did not create any APIs to achieve this.  Data on the server is synchronized with data on the client for you.

### Chapter 3: Creating the Top Level App Structure

Now that we have all of our pieces in place, lets build our application.

Replace the entire contents of `app.rb` with:

```ruby
# app/hyperloop/components/app.rb
class App < Hyperloop::Component
  render(SECTION) do
    Header()
    Index()
    Footer()
  end
end
```

The browser screen will go blank because we have not defined the three subcomponents.  Lets define them now:

Add three new ruby files to the `app/hyperloop/components` folder:

```ruby
# app/hyperloop/components/header.rb
class Header < Hyperloop::Component
  render(HEADER) do
    'Header will go here'
  end
end
```

```ruby
# app/hyperloop/components/index.rb
class Index < Hyperloop::Component
  render(SECTION) do
    'List of Todos will go here'
  end
end
```

```ruby
# app/hyperloop/components/footer.rb
class Footer < Hyperloop::Component
  render(DIV) do
    'Footer will go here'
  end
end
```

Once you add the Footer component you should see:

  <div style="border:solid; margin-left: 10px; padding: 10px">
    <div>Header will go here</div>
    <div>List of Todos will go here</div>  
    <div>Footer will go here</div>  
  </div>
  <br>

If you don't, restart the server, and reload the browser.

Notice how the usual HTML tags such as DIV, SECTION, and HEADER are all available as well as all the other HTML and SVG tags.

### Chapter 4: Listing the Todos, HyperReact Params, and Prerendering

To display each Todo we will create a TodoItem component that takes a parameter:

```ruby
# app/hyperloop/components/todo_item.rb
class TodoItem < Hyperloop::Component
  param :todo
  render(LI) do
    params.todo.title
  end
end
```

We can use this component in our Index component:

```ruby
# app/hyperloop/components/index.rb
class Index < Hyperloop::Component
  render(SECTION) do
    UL do
      Todo.each do |todo|
        TodoItem(todo: todo)
      end
    end
  end
end
```

Now you will see something like

  <div style="border:solid; margin-left: 10px; padding: 10px">
    <div>Header will go here</div>
    <ul>
      <li>my first todo</li>
      <li>my second todo</li>
    </ul>
    <div>Footer will go here</div>
  </div>
  <br>

As you can see components can take parameters (or props in react.js terminology.)

>*Rails uses the terminology params (short for parameters) which have a similar purpose to React props, so to make the transition more natural for Rails programmers Hyperloop uses params, rather than props.*

Params are declared using the `param` macro and are accessed via the `params` object.
In our case we *mount* a new TodoItem with each Todo record and pass the Todo as the parameter.   

Now go back to Rails console and type
```ruby
  Todo.last.update(title: 'updated todo')
```
and you will see the last Todo in the list changing.

Try adding another Todo using `create` like you did before. You will see the new Todo is added to the list.


### Chapter 5: Adding Inputs to Components

So far we have seen how our components are synchronized to the data that they display.  Next let's add the ability for the component to *change* the underlying data.

First add an `INPUT` html tag to your TodoItem component like this:

```ruby
# app/hyperloop/components/todo_item.rb
class TodoItem < Hyperloop::Component
  param :todo
  render(LI) do
    INPUT(type: :checkbox, checked: params.todo.completed)
    params.todo.title
  end
end
```

You will notice that while it does display the checkboxes, you can not change them by clicking on them.

For now we can change them via the console like we did before.  Try executing
```ruby
  Todo.last.update(completed: true)
```  
and you should see the last Todo's `completed` checkbox changing state.

To make our checkbox input change its own state, we will add an `event handler` for the change event:

```ruby
# app/hyperloop/components/todo_item.rb
class TodoItem < Hyperloop::Component
  param :todo
  render(LI) do
    INPUT(type: :checkbox, checked: params.todo.completed)
      .on(:click) { params.todo.update(completed: !params.todo.completed) }
    params.todo.title
  end
end
```
It reads like a good novel doesn't it?  On a `click` event update the todo, setting the completed attribute to the opposite of its current value.

Meanwhile HyperReact sees the value of `params.todo.checked` changing, and this causes the associated HTML INPUT tag to be re-rendered.

We will finish up by adding a delete link at the end of the Todo item:

```ruby
# app/hyperloop/components/todo_item.rb
class TodoItem < Hyperloop::Component
  param :todo
  render(LI) do
    INPUT(type: :checkbox, checked: params.todo.completed)
      .on(:click) { params.todo.update(completed: !params.todo.completed) }
    SPAN { params.todo.title } # See note below...
    A { ' -X-' }.on(:click) { params.todo.destroy }
  end
end
```

*Note: If a component or tag block returns a string it is automatically wrapped in a SPAN, to insert a string in the middle you have to wrap it a SPAN like we did above.*

I hope you are starting to see a pattern here.  HyperReact components determine what to display based on the `state` of some
objects.  External events, such as mouse clicks, the arrival of new data from the server, and even timers update the `state`.  HyperReact recomputes whatever portion of the display depends on the `state` so that the display is always in sync with the `state`.  In our case the objects are the Todo model and its associated records, which have a number of associated internal `states`.  

By the way, you don't have to use Models to have states.  We will see later that states can be as simple as boolean instance variables.

### Chapter 6: Routing

Now that Todos can be *completed* or *active*, we would like our user to be able display either "all" Todos,
only "completed" Todos, or "active" (or incomplete) Todos.  We want our URL to reflect which filter is currently being displayed.
So `/all` will display all todos, `/completed` will display the completed Todos, and of course `/active` will display only active
(or incomplete) Todos.  We would also like the root url `/` to be treated as `/all`

To achieve this we first need to be able to *scope* (or filter) the Todo Model. So let's edit the Todo model file so it looks like this:

```ruby
# app/hyperloop/models/todo.rb
class Todo < ApplicationRecord
  scope :completed, -> () { where(completed: true)  }
  scope :active,    -> () { where(completed: false) }
end
```

Now we can say `Todo.all`, `Todo.completed`, and `Todo.active`, and get the desired subset of Todos.
You might want to try it now in the rails console.  *Note: you will have to do a `reload!` to load the changes to the Model.*

We would like the URL of our App to reflect which of these *filters* is being displayed.  So if we load

+ `/all` we want the Todo.all scope to be run;
+ `/completed` we want the Todo.completed scope to be run;
+ `/active` we want the Todo.active scope to be run;
+ `/` (by itself) then we should redirect to `/all`.

Having the application display different data (or whole different components) based on the URL is called routing.  

Lets change `App` to look like this:

```ruby
# app/hyperloop/components/app.rb
class App < Hyperloop::Router
  history :browser
  route do # note instead of render we use the route method
    SECTION do
      Header()
      Route('/', exact: true) { Redirect('/all') }
      Route('/:scope', mounts: Index)
      Footer()
    end
  end
end
```
and the `Index` component to look like this:

```ruby
# app/hyperloop/components/index.rb
class Index < Hyperloop::Router::Component
  render(SECTION) do
    UL do
      Todo.send(match.params[:scope]).each do |todo|
        TodoItem(todo: todo)
      end
    end
  end
end
```
*Note that because we have changed the class of these components the hot reloader will break, and you will have to refresh the page and possibly your local server.*

Lets walk through the changes:
+ `App` now inherits from `Hyperloop::Router` which is a subclass of `Hyperloop::Component` with *router* capabilities added.
+ The `history` macro tells the router how to track the history (back/forward buttons).  
The `:browser` history tracks the history invisibly in the html5 browser history.
The other common option is the `:hash` history which tracks the history in the url hash.
+ The `render` macro is replaced by `route`, and the `DIV` tag is moved inside the route block.
+ We mount the `Header` components as before.
+ We then check to see if the current route exactly matches `/` and if it does, redirect to `/all`.
+ Then instead of directly mounting the `Index` component, we *route* to it based on the URL.  In this case if the url must look like `/xxx`.
+ `Index` now inherits from `Hyperloop::Router::Component` which is a subclass of `Hyperloop::Component` with methods like `match` added.
+ Instead of simply enumerating all the Todos, we decide which *scope* to filter using the URL fragment *matched* by `:scope`.  

Notice the relationship between `Route('/:scope', mounts: Index)` and `match.params[:scope]`:

During routing each `Route` is checked.  If it *matches* then the
indicated component is mounted, and the match parameters are saved for that component to use.

You should now be able to change the url from `/all`, to `/completed`, to `/active`, and see a different set of Todos.  For example if you are displaying the `/active` Todos, you will only see the Todos that are not complete.  If you check one of these it will disappear from the list.

>*Rails also has the concept of routing, so how do the Rails and Hyperloop routers interact?  Have a look at the config/routes.rb file.  You will see a line like this:  
`  get '/(*other)', to: 'hyperloop#app'`  
This is telling Rails to accept all requests and to process them using the `hyperloop` controller, which will attempt to mount a component named `App` in response to the request.  The mounted App component is then responsible for further processing the URL*  

>*For more complex scenarios Hyperloop provides Rails helper methods that can be used to mount components from your controllers, layouts, and views*

### Chapter 7:  Helper Methods, Inline Styling, Active Support and Router Nav Links

Of course we will want to add navigation to move between these routes.  We will put the navigation in the footer:

```ruby
# app/hyperloop/components/footer.rb
class Footer < Hyperloop::Component
  def link_item(path)
    A(href: "/#{path}", style: { marginRight: 10 }) { path.camelize }
  end
  render(DIV) do
    link_item(:all)
    link_item(:active)
    link_item(:completed)
  end
end
```
Save the file, and you will now have 3 links, that you will change the path between the three options.  

Here is how the changes work:
+ Hyperloop is just Ruby, so you are free to use all of Ruby's rich feature set to structure your code. For example the `link_item` method is just a *helper* method to save us some typing.
+ The `link_item` method uses the `path` argument to construct an HTML *Anchor* tag.
+ Hyperloop comes with a large portion of the Rails active-support library.  For the text of the anchor tag we use the active-support method `camelize`.
+ Later we will add proper css classes, but for now we use an inline style.  Notice that the css `margin-right` is written `marginRight`, and that `10px` can be expressed as the integer 10.

Notice that as you click each link the page reloads.  **However** what we really want is for the links to simply change the route, without reloading the page.

To make this happen we will *mixin* some router helpers by *including* `HyperRouter::ComponentMethods` inside of class.

Then we can replace the anchor tag with the Router's `NavLink` component:

Change

```ruby
  A(href: "/#{path}", style: { marginRight: 10 }) { path.camelize }
```
to

```ruby
  NavLink("/#{path}", style: { marginRight: 10 }) { path.camelize }
```

Our component should now look like this:

```ruby
# app/hyperloop/components/footer.rb
class Footer < Hyperloop::Component
  include HyperRouter::ComponentMethods
  def link_item(path)
    NavLink("/#{path}", style: { marginRight: 10 }) { path.camelize }
  end
  render(DIV) do
    link_item(:all)
    link_item(:active)
    link_item(:completed)
  end
end
```
After this change you will notice that changing routes *does not* reload the page, and after clicking to different routes, you can use the browsers forward and back buttons.

How does it work?  The `NavLink` component reacts to a click just like an anchor tag, but instead of changing the window's URL directly, it updates the *HTML5 history object.*
Associated with this history is a (you guessed it, I hope) *state*.  So when the history changes it causes any components depending on the current URL to be re-rendered.

### Chapter 8: Create a Basic EditItem Component
So far we can mark Todos as completed, delete them, and filter them.  Now we create an `EditItem` component so we can change the Todo title.

Add a new component like this:

```ruby
# app/hyperloop/components/edit_item.rb
class EditItem < Hyperloop::Component
  param :todo
  render do
    INPUT(defaultValue: params.todo.title)
      .on(:key_down) do |evt|
        next unless evt.key_code == 13
        params.todo.update(title: evt.target.value)
      end
  end
end
```
Before we use this component let's understand how it works.
+ It receives a `todo` param which will be edited by the user;
+ The `title` of the todo is displayed as the initial value of the input;
+ When the user types the enter key (key code 13) the todo is saved.

Now update the `TodoItem` component replacing

```ruby
  SPAN { params.todo.title }
```
with

```ruby
  EditItem(todo: params.todo)
```
Try it out by changing the text of some our your Todos followed by the enter key.  Then refresh the page to see that the Todos have changed.

### Chapter 9: Adding State to a Component, Defining Custom Events, and a Lifecycle Callback.
This all works, but its hard to use.  There is no feed back indicating that a Todo has been saved, and there is no way to cancel after starting to edit.
We can make the user interface much nicer by adding *state* (there is that word again) to the `TodoItem`.
We will call our state `editing`.  If `editing` is true, then we will display the title in a `EditItem` component, otherwise we will display it in a `LABEL` tag.
The user will change the state to `editing` by double clicking on the label.  When the user saves the Todo, we will change the state of `editing` back to false.
Finally we will let the user *cancel* the edit by moving the focus away (the `blur` event) from the `EditItem`.
To summarize:
+ User double clicks on any Todo title: editing changes to `true`.
+ User saves the Todo being edited: editing changes to `false`.
+ User changes focus away (`blur`) from the Todo being edited: editing changes to `false`.
In order to accomplish this our `EditItem` component is going to communicate via two callbacks - `on_save` and `on_cancel` - with the parent component.  We can think of these callbacks as custom events, and indeed as we shall see they will work just like any other event.
Add the following 5 lines to the `EditItem` component like this:

```ruby
# app/hyperloop/components/edit_item.rb
class EditItem < Hyperloop::Component
  param :todo
  param :on_save, type: Proc               # add
  param :on_cancel, type: Proc             # add
  after_mount { Element[dom_node].focus }  # add

  render do
    INPUT(defaultValue: params.todo.title)
      .on(:key_down) do |evt|
        next unless evt.key_code == 13
        params.todo.update(title: evt.target.value)
        params.on_save                       # add
      end
      .on(:blur) { params.on_cancel }        # add
  end
end
```
The first two lines add our callbacks.  In HyperReact (and React.js) callbacks are just params.
Giving them `type: Proc` and beginning their name with `on_` means that HyperReact will treat them syntactically like events (as we will see.)  

The next line uses one of several *Lifecycle Callbacks*.  In this case we need to move the focus to the `EditItem` component after is mounted.
The `Element` class is Hyperloop's jQuery wrapper, and `dom_node`
is the method that returns the actual dom node where this instance of the component is mounted.

The `params.on_save` line will call the provided callback.  Notice that because we declared `on_save` as type `Proc`,
when we refer to it in the component it invokes the callback rather than returning the value.
For example, if we had left off `type: Proc` we would have to say `params.on_save.call`.

Finally we add the `blur` event handler and simply transform it into our custom `cancel` event.

Now we can update our `TodoItem` component to be a little state machine, which will react to three events:  `double_click`, `save` and `cancel`.

```ruby
# app/hyperloop/components/todo_item.rb
class TodoItem < Hyperloop::Component
  param :todo
  state editing: false
  render(LI) do
    if state.editing
      EditItem(todo: params.todo)
        .on(:save, :cancel) { mutate.editing false }
    else
      INPUT(type: :checkbox, checked: params.todo.completed)
        .on(:click) { params.todo.update(completed: !params.todo.completed) }
      LABEL { params.todo.title }
        .on(:double_click) { mutate.editing true }
      A { ' -X-' }
        .on(:click) { params.todo.destroy }
    end
  end
end
```
First we declare a *state variable* called `editing` that is initialized to `false`.

We have already used a lot of states that are built into the HyperModel and HyperRouter. The state machines in these complex objects are built out of simple state variables like the `editing`.

State variables are *just like instance variables* with the added power that when they change, any dependent components will be updated with the change.

You read a state variable using the `state` method (similar to the `params` method) and you change state variables using the `mutate` method.  Whenever you want to change a state variable whether its a simple assignment or changing the internal value of a complex structure like a hash or array you use the `mutate` method.

Lets read on:  Next, we see `if state.editing...`.  When the component executes this `if` statement, it reads the value of the `editing` state variable and will either render the `EditItem` or the input, label, and anchor tags.  In this way the `editing` state variable is acting no different than any other Ruby instance variable.  *But here is the key: The component now knows that if the value of the editing state changes, it must re-render this TodoItem.  When state variables are referenced by a component the component will keep track of this, and will re-rerender when the state changes.*

Because `editing` starts off false, when the TodoItem first mounts, it renders the input, label, and anchor tags.  Attached to the label tag is a `double_click` handler which does one thing:  *mutates* the editing state.  This then causes the component to re-render, and now instead of the three tags, we will render the `EditItem` component.

Attached to the `EditItem` component is the `save` and `cancel` handler (which is shared between the two events) that *mutates* the editing state, setting it back to false.

Notice that just as you read params using the `params` method, you read state variables using the `state` method.  Note that `state` is singular because we commonly think of the 'state' of an object as singular entity.

### Chapter 10: Using EditItem to create new Todos

Our EditItem component has a good robust interface.  It takes a Todo, and lets the user edit the title, and then either save or cancel, using two event style callbacks to communicate back outwards.

Because of this we can easily reuse EditItem to create new Todos.  Not only does this save us time, but it also insures that the user interface acts consistently.

Update the `Header` component to use EditItem like this:

```ruby
# app/hyperloop/components/header.
class Header < Hyperloop::Component
  state(:new_todo) { Todo.new }
  render(HEADER) do
    EditItem(todo: state.new_todo)
      .on(:save) { mutate.new_todo Todo.new }
  end
end
```
What we have done is create a state variable called `new_todo` and we have initialized it using a block that will return `Todo.new`.  The reason we use a block is to insure that we don't call `Todo.new` until after the system is loaded, at which point all state initialization blocks will be run.  A good rule of thumb is to use the block notation unless the initial value is a constant.

Then we pass the value of the state variable to EditItem, and when it is saved, we generate another new Todo and save it the `new_todo` state variable.

Notice `new_todo` is a state variable that is used in Header, so when it is mutated, it will cause a re-render of the Header, which will then pass the new value of `new_todo`, to EditItem, causing that component to re-render.  

We don't care if the user cancels the edit, so we simply don't provide a `:cancel` event handler.

Once the code is added a new input box will appear at the top of the window, and when you type enter a new Todo will be added to the list.

However you will notice that the value of new Todo input box does not clear.  This is subtle problem that is easy to fix.

React treats the `INPUT` tags `defaultValue` specially.  It is only read when the `INPUT` is first mounted, so it *does not react* to changes like normal
parameters.  Our `Header` component does pass in
new Todo records, but even though they are changing React *does not* update the INPUT.

We can easily fix this by adding a `key` param to the `INPUT` that is associated with each unique Todo.
In Ruby this is easy as every object has an `object_id` method that is guaranteed to return a unique value.

Changing the value of the key, will inform React that we are referring to a new Todo, and thus a  new `INPUT` element will have to be mounted.

```ruby
  ...
  INPUT(defaultValue: params.todo.title, key: params.todo.object_id)
  ...
```

### Chapter 11: Adding Styling

We are just going to steal the style sheet from the benchmark Todo app, and add it to our assets.

**Go grab the file in this repo here:** https://github.com/ruby-hyperloop/todo-tutorial/blob/master/app/assets/stylesheets/todo.css
and copy it to a new file called `todo.css` in the `app/assets/stylesheets/` directory.

You will have to refresh the page after changing the style sheet.

Now its a matter of updating the css classes which are passed to components via the `class` parameter.

Let's start with the `App` component.  With styling it will look like this:

```ruby
# app/hyperloop/components/app.rb
class App < Hyperloop::Router
  history :browser
  route do
    SECTION(class: 'todo-app') do # add the class param
      Header()
      Route('/:scope', mounts: Index)
      Footer()
    end
  end
end
```
The `Footer` components needs have a `UL` added to hold the links nicely,
and we can also use the `NavLinks` `active_class` param to highlight the link that is currently active:

```ruby
# app/hyperloop/components/footer.rb
class Footer < Hyperloop::Component
  include HyperRouter::ComponentMethods
  def link_item(path)
    # wrap the NavLink in a LI and
    # tell the NavLink to change the class to :selected when
    # the current (active) path equals the NavLink's path.
    LI { NavLink("/#{path}", active_class: :selected) { path.camelize } }
  end
  render(DIV, class: :footer) do   # add class
    UL(class: :filters) do         # wrap links in a UL
      link_item(:all)
      link_item(:active)
      link_item(:completed)
    end
  end
end
```
For the Index component just add the `main` and `todo-list` classes.

```ruby
# app/hyperloop/components/index.rb
class Index < Hyperloop::Router::Component
  render(SECTION, class: :main) do         # add class main
    UL(class: 'todo-list') do              # add class todo-list
      Todo.send(match.params[:scope]).each do |todo|
        TodoItem(todo: todo)
      end
    end
  end
end
```
For the EditItem component we want the caller specify the class.  To keep things compatible with React.js we need to call the param `className`,
but we can still send it to EditItem with the usual hyperloop style `class` param.  

```ruby
# app/hyperloop/components/edit_item.rb
class EditItem < Hyperloop::Component
  param :todo
  param :on_save, type: Proc
  param :on_cancel, type: Proc
  param :className # recieves class params
  after_mount { Element[dom_node].focus }
  render do
    # pass the className param as the INPUT's class
    INPUT(
      class: params.className,
      defaultValue: params.todo.title,
      key: params.todo.object_id
    ).on(:key_down) do |evt|
      next unless evt.key_code == 13
      params.todo.update(title: evt.target.value)
      params.on_save
    end
    .on(:blur) { params.on_cancel }
  end
end
```
Now we can add classes to the TodoItem's list-item, input, anchor tags, and to the `EditItem` component:

```ruby
# app/hyperloop/components/todo_item.rb
class TodoItem < Hyperloop::Component
  param :todo
  state editing: false
  render(LI, class: 'todo-item') do
    if state.editing
      EditItem(class: :edit, todo: params.todo)
        .on(:save, :cancel) { mutate.editing false }
    else
      INPUT(type: :checkbox, class: :toggle, checked: params.todo.completed)
        .on(:click) { params.todo.update(completed: !params.todo.completed) }
      LABEL { params.todo.title }
        .on(:double_click) { mutate.editing true }
      A(class: :destroy) # also remove the { '-X-' } placeholder
        .on(:click) { params.todo.destroy }
    end
  end
end
```
In the Header we can send a different class to the `EditItem` component.  While we are at it
we will add the `H1 { 'todos' }` hero unit.

```ruby
# app/hyperloop/components/header.rb
class Header < Hyperloop::Component
  state(:new_todo) { Todo.new }
  render(HEADER, class: :header) do                   # add the 'header' class
    H1 { 'todos' }                                    # Add the hero unit.
    EditItem(class: 'new-todo', todo: state.new_todo) # add 'new-todo' class
      .on(:save) { mutate.new_todo Todo.new }
  end
end
```
At this point your Todo App should be properly styled.

### Chapter 12: Other Features

+ **Show How Many Items Left In Footer**  
This is just a span that we add before the link tags list in the Footer component:

  ```ruby
  ...
  render(DIV, class: :footer) do
    SPAN(class: 'todo-count') do
      "#{Todo.active.count} item#{'s' if Todo.active.count != 1} left"
    end
    UL(class: :filters) do
    ...
  ```
+ **Add 'placeholder' Text To Edit Item**  
EditItem should display a meaningful placeholder hint if the title is blank:   

  ```ruby
    ...
    INPUT(
      class: params.className,
      defaultValue: params.todo.title,
      key: params.todo.object_id,
      placeholder: 'What is left to do today?'
    ).on(:key_down) do |evt| ...
    ...
  ```
+ **Don't Show the Footer If There are No Todos**  
In the `App` component add a *guard* so that we won't show the Footer if there are no Todos:  

  ```ruby
  ...
      Footer() unless Todo.count.zero?
  ...
  ```


Congratulations! you have completed the tutorial.

### Summary

You have built a small but feature rich full stack Todo application in less than 100 lines of code:

```text
SLOC  
--------------  
App:        11  
Header:      8
Index:       9  
TodoItem:   17  
EditItem:   21  
Footer:     16  
Todo Model:  4  
Rails Route: 1  
--------------  
Total:      87  
```

The complete application is shown here:

```ruby
# app/hyperloop/components/app.rb
class App < Hyperloop::Router
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

# app/hyperloop/components/header.rb
class Header < Hyperloop::Component
  state(:new_todo) { Todo.new }
  render(HEADER, class: :header) do
    H1 { 'todos' }
    EditItem(class: 'new-todo', todo: state.new_todo)
      .on(:save) { mutate.new_todo Todo.new }
  end
end

# app/hyperloop/components/index.rb
class Index < Hyperloop::Router::Component
  render(SECTION, class: :main) do
    UL(class: 'todo-list') do
      Todo.send(match.params[:scope]).each do |todo|
        TodoItem(todo: todo)
      end
    end
  end
end

# app/hyperloop/components/footer.rb
class Footer < Hyperloop::Component
  include HyperRouter::ComponentMethods
  def link_item(path)
    LI { NavLink("/#{path}", active_class: :selected) { path.camelize } }
  end
  render(DIV, class: :footer) do
    SPAN(class: 'todo-count') do
      "#{Todo.active.count} item#{'s' if Todo.active.count != 1} left"
    end
    UL(class: :filters) do
      link_item(:all)
      link_item(:active)
      link_item(:completed)
    end
  end
end

# app/hyperloop/components/todo_item.rb
class TodoItem < Hyperloop::Component
  param :todo
  state editing: false
  render(LI, class: 'todo-item') do
    if state.editing
      EditItem(todo: params.todo, class: :edit)
        .on(:save, :cancel) { mutate.editing false }
    else
      INPUT(type: :checkbox, class: :toggle, checked: params.todo.completed)
        .on(:click) { params.todo.update(completed: !params.todo.completed) }
      LABEL { params.todo.title }
        .on(:double_click) { mutate.editing true }
      A(class: :destroy).on(:click) { params.todo.destroy }
    end
  end
end

# app/hyperloop/components/edit_item.rb
class EditItem < Hyperloop::Component
  param :todo
  param :on_save, type: Proc               
  param :on_cancel, type: Proc             
  param :className
  after_mount { Element[dom_node].focus }  

  render do
    INPUT(
      class: params.className,
      defaultValue: params.todo.title,
      key: params.todo.object_id,
      placeholder: 'What is left to do today?'
    ).on(:key_down) do |evt|
      next unless evt.key_code == 13
      params.todo.update(title: evt.target.value)
      params.on_save                       
    end
    .on(:blur) { params.on_cancel }
  end
end

# app/hyperloop/models/todo.rb
class Todo < ApplicationRecord
  scope :completed, -> () { where(completed: true)  }
  scope :active,    -> () { where(completed: false) }
end

# config/routes.rb
Rails.application.routes.draw do
  mount Hyperloop::Engine => '/hyperloop'
  get '/(*other)', to: 'hyperloop#app'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
```

### General troubleshooting

1: Wait. On initial boot it can take several minutes to pre-compile all the system assets.  

2: Make sure to save (or better yet do a git commit) after every instruction so that you can backtrack

3: Its possible to get things so messed up the hot-reloader will not work.  Restart the server and reload the browser.

You can find the final application source code here:
