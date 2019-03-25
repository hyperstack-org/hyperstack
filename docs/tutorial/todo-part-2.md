
# TodoMVC Tutorial Part II

### Prerequisites

{ [Familarity with the TodoMVC tutorial Part I](https://hyperstack.org/edge/docs/tutorials/todo) }

### The Goals of this Tutorial

In this tutorial, will investigate the advanced concepts of

1. *prerendering*,
2. the `while_loading` method and
3. optimizing ActiveRecord scopes to run on the client.

None of the techniques are necessary to build large complex applications, but they are useful to know to build the possible user experience.

### Skills required

Basic knowledge of Rails is helpful, and ability to follow the basic TodoMVC example on which this is based.

### Chapter 1: Setting Things Up

You can just read this tutorial, or if you want to follow along clone the working Todo application from this directory ... (or do we want to use the rail's template mechanism)

Once setup you should be able to start the rails app and hot reloader by running:

+ `bundle exec foreman start`
+ visit `localhost:5000`

Add about 4-6 random Todo's and mark about half as completed.

### Chapter 2:  Prerendering

When you first load the Todo app you will see a brief flash between the first load, and complete display of the list of Todos.

What is going on?

When you first load a Hyperstack application, you get all the code compiled in to Javascript, along with instructions to React on how to mount your top level component.

In our case the Todo App is mounted, which will then render the list of the Todo's.  The list of Todo's are still on the server, so once the App is mounted and rendered we then have to wait a few 100 milliseconds for the actual data to arrive from the server.

These steps - starting Hyperstack, rendering the application, waiting for data, and re-rendering takes enough time and is visually noticeable as a brief flicker.  On larger apps the download time of the Hyperstack will also be noticable.

The solution is called pre-rerendering.  Prerendering runs all the steps before the page is delivered on the server.  The result is that the page comes down already rendered in its final state.  After page is loaded all the event handlers are then attached so that the page's components can continue to be updated reactively.

To turn on prerendering you change the Hyperstack configuration in the initializer from `prerendering = :off` to `:on`

```ruby
# config/initializers/hyperstack.rb
Hyperstack.configuration do |config|
  config.transport = :action_cable
  config.prerendering = :off # switch to on to turn on prerendering
  ...
end
```

Restart the server and prerendering is enabled.  

Hypestack comes configured with prerendering off, because javsacript errors during prerendering occur on the server within the headless javscript environment and are thus much harder to debug.  Once the application is working properly its easy to turn prerendering on.

>A Rails ActiveRecord Model is a Ruby class that is backed by a database table.  In this example we will have one model class called `Todo`.
When manipulating models, Rails automatically generates the necessary SQL code for you.  So when `Todo.all` is evaluated Rails
generates the appropriate SQL and turns the result of the query into appropriate Ruby data structures.

**Hyperstack Models are extensions of ActiveRecord Models that synchronize the data between the client and server
automatically for you.  So now `Todo.all` can be evaluated on the server or the client.**

Okay lets see it in action:

1. **Add the Todo Model:**  

  In your second terminal window run **on a single line**:   
  ```text
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

2. **Make Your Model Public:**   

  *Move* `models/todo.rb` to `hyperstack/models`

  This will make the model accessible on the clients *and the server*, subject to any data access policies.

  *Note: The hyperstack installer adds a policy that gives full permission to all clients but only in development and test modes.  Have a look at `app/policies/application_policy` if you are interested.*

3. **Try It**  

  Now change your `App` component's render method to:  
  ```ruby
  class App < HyperComponent
    include Hyperstack::Router
    render do
       H1 { "Number of Todos: #{Todo.count}" }
    end
  end
  ```  

   You will now see **Number of Todos: 0** displayed.

   Now start a rails console
   ```ruby
    bundle exec rails c
   ```
   and type:  
   ```ruby
     Todo.create(title: 'my first todo')
   ```  
   This will create a new Todo in the server's database, which will cause your Hyperstack application to be
   updated and you will see the count change to 1!   

   Try it again:  
   ```ruby
     Todo.create(title: 'my second todo')
   ```  
   and you will see the count change to 2!   

Are we having fun yet?  I hope so!  As you can see Hyperstack is synchronizing the Todo model between the client and server.  As the state of the database changes, Hyperstack buzzes around updating whatever parts of the DOM were dependent on that data (in this case the count of Todos).

Notice that we did not create any APIs to achieve this.  Data on the server is synchronized with data on the client for you.

### Chapter 3: Creating the Top Level App Structure

Now that we have all of our pieces in place, lets build our application.

Replace the entire contents of `app.rb` with:

```ruby
# app/hyperstack/components/app.rb
class App < HyperComponent
  include Hyperstack::Router
  render(SECTION) do
    Header()
    Index()
    Footer()
  end
end
```

After saving you will see the following error displayed:

**Uncaught error: Header: undefined method `Header' for #<App:0x970>  
in App (created by Hyperstack::Internal::Component::TopLevelRailsComponent)  
in Hyperstack::Internal::Component::TopLevelRailsComponent**

because have not defined the three subcomponents.  Lets define them now:

Add three new ruby files to the `app/hyperstack/components` folder:

```ruby
# app/hyperstack/components/header.rb
class Header < HyperComponent
  render(HEADER) do
    'Header will go here'
  end
end
```

```ruby
# app/hyperstack/components/index.rb
class Index < HyperComponent
  render(SECTION) do
    'List of Todos will go here'
  end
end
```

```ruby
# app/hyperstack/components/footer.rb
class Footer < HyperComponent
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

>Hyperstack uses the following conventions to easily distinguish between HTML tags, application defined components and other helper methods:
> + HTML tags are in all caps
> + Application components are CamelCased
> + other helper methods are snake_cased

### Chapter 4: Listing the Todos, Hyperstack Params, and Prerendering

To display each Todo we will create a TodoItem component that takes a parameter:

```ruby
# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI) do
    @Todo.title
  end
end
```

We can use this component in our Index component:

```ruby
# app/hyperstack/components/index.rb
class Index < HyperComponent
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

>*Rails uses the terminology params (short for parameters) which have a similar purpose to React props, so to make the transition more natural for Rails programmers Hyperstack uses params, rather than props.*

Params are declared using the `param` macro and are accessed via Ruby *instance variables*.  Notice that the instance variable name
is *CamelCased* so that it is easily distinguished from other
instance variables.

Our `Index` component *mounts* a new `TodoItem` with each `Todo` record and passes the `Todo` to the `TodoItem` component as the parameter.   

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
# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI) do
    INPUT(type: :checkbox, checked: @Todo.completed)
    @Todo.title
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
# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI) do
    INPUT(type: :checkbox, checked: @Todo.completed)
    .on(:change) { @Todo.update(completed: !@Todo.completed) }
    @Todo.title
  end
end
```
It reads like a good novel doesn't it?  On the `change` event update the todo, setting the completed attribute to the opposite of its current value.  The rest of coordination between the database and the display is taken care of for you by the Hyperstack.  

After saving your changes you should be able change the `completed` state of each Todo, and check on the rails console (say by checking `Todo.last.completed`) and you will see that the value has been persisted to the database.  You can also demonstrate this by refreshing the page.

We will finish up by adding a *delete* link at the end of the Todo item:

```ruby
# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI) do
    INPUT(type: :checkbox, checked: @Todo.completed)
    .on(:change) { @Todo.update(completed: !@Todo.completed) }
    SPAN { @Todo.title } # See note below...
    A { ' -X-' }.on(:click) { @Todo.destroy }
  end
end
```
*Note: If a component or tag block returns a string it is automatically wrapped in a SPAN, to insert a string in the middle you have to wrap it a SPAN like we did above.*

I hope you are starting to see a pattern here.  Hyperstack components determine what to display based on the `state` of some
objects.  External events, such as mouse clicks, the arrival of new data from the server, and even timers update the `state`.  Hyperstack recomputes whatever portion of the display depends on the `state` so that the display is always in sync with the `state`.  In our case the objects are the Todo model and its associated records, which have a number of associated internal `states`.  

By the way, you don't have to use Models to have states.  We will see later that states can be as simple as boolean instance variables.

### Chapter 6: Routing

Now that Todos can be *completed* or *active*, we would like our user to be able display either "all" Todos,
only "completed" Todos, or "active" (or incomplete) Todos.  We want our URL to reflect which filter is currently being displayed.
So `/all` will display all todos, `/completed` will display the completed Todos, and of course `/active` will display only active
(or incomplete) Todos.  We would also like the root url `/` to be treated as `/all`

To achieve this we first need to be able to *scope* (or filter) the Todo Model. So let's edit the Todo model file so it looks like this:

```ruby
# app/hyperstack/models/todo.rb
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
# app/hyperstack/components/app.rb
class App < HyperComponent
  include Hyperstack::Router
  render do
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
# app/hyperstack/components/index.rb
class Index < HyperComponent
  include Hyperstack::Router::Helpers
  render(SECTION) do
    UL do
      Todo.send(match.params[:scope]).each do |todo|
        TodoItem(todo: todo)
      end
    end
  end
end
```

Lets walk through the changes:
+ We mount the `Header` components as before.
+ We then check to see if the current route exactly matches `/` and if it does, redirect to `/all`.
+ Then instead of directly mounting the `Index` component, we *route* to it based on the URL.  In this case if the url must look like `/xxx`.
+ `Index` now includes (mixes-in) the `Hyperstack::Router::Helpers` module which has methods like `match`.
+ Instead of simply enumerating all the Todos, we decide which *scope* to filter using the URL fragment *matched* by `:scope`.  

Notice the relationship between `Route('/:scope', mounts: Index)` and `match.params[:scope]`:

During routing each `Route` is checked.  If it *matches* then the
indicated component is mounted, and the match parameters are saved for that component to use.

You should now be able to change the url from `/all`, to `/completed`, to `/active`, and see a different set of Todos.  For example if you are displaying the `/active` Todos, you will only see the Todos that are not complete.  If you check one of these it will disappear from the list.

>Rails also has the concept of routing, so how do the Rails and Hyperstack routers interact?  Have a look at the config/routes.rb file.  You will see a line like this:  
  `get '/(*other)', to: 'hyperstack#app'`  
This is telling Rails to accept all requests and to process them using the `Hyperstack` controller, which will attempt to mount a component named `App` in response to the request.  The mounted App component is then responsible for further processing the URL.  
>
>For more complex scenarios Hyperstack provides Rails helper methods that can be used to mount components from your controllers, layouts, and views.

### Chapter 7:  Helper Methods, Inline Styling, Active Support and Router Nav Links

Of course we will want to add navigation to move between these routes.  We will put the navigation in the footer:

```ruby
# app/hyperstack/components/footer.rb
class Footer < HyperComponent
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
+ Hyperstack is just Ruby, so you are free to use all of Ruby's rich feature set to structure your code. For example the `link_item` method is just a *helper* method to save us some typing.
+ The `link_item` method uses the `path` argument to construct an HTML *Anchor* tag.
+ Hyperstack comes with a large portion of the Rails active-support library.  For the text of the anchor tag we use the active-support method `camelize`.
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
  # note that there is no href key in NavLink
```

Our component should now look like this:

```ruby
# app/hyperstack/components/footer.rb
class Footer < HyperComponent
  include Hyperstack::Router::Helpers
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
Associated with this history is (hope you guessed it) *state*.  So when the history changes it causes any components depending on the state of the URL to be re-rendered.

### Chapter 8: Create a Basic EditItem Component
So far we can mark Todos as completed, delete them, and filter them.  Now we create an `EditItem` component so we can change the Todo title.

Add a new component like this:

```ruby
# app/hyperstack/components/edit_item.rb
class EditItem < HyperComponent
  param :todo
  render do
    INPUT(defaultValue: @Todo.title)
    .on(:enter) do |evt|
      @Todo.update(title: evt.target.value)
    end
  end
end
```
Before we use this component let's understand how it works.
+ It receives a `todo` param which will be edited by the user;
+ The `title` of the todo is displayed as the initial value of the input;
+ When the user types the enter key updated.

Now update the `TodoItem` component replacing

```ruby
  SPAN { @Todo.title }
```
with

```ruby
  EditItem(todo: @Todo)
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

In order to accomplish this our `EditItem` component is going to communicate to its parent via two application defined events - `save` and `cancel` .  
Add the following 5 lines to the `EditItem` component like this:

```ruby
# app/hyperstack/components/edit_item.rb
class EditItem < HyperComponent
  param :todo
  triggers :save                             # add
  triggers :cancel                           # add
  after_mount { DOM[dom_node].focus }        # add

  render do
    INPUT(defaultValue: @Todo.title)
    .on(:enter) do |evt|
      @Todo.update(title: evt.target.value)
      save!                                  # add
    end
    .on(:blur) { cancel! }                   # add
  end
end
```
The first two new lines add our custom events.  

The next new line uses one of several *Lifecycle Callbacks*.  In this case we need to move the focus to the `EditItem` component after is mounted.
The `DOM` class is Hyperstack's jQuery wrapper, and `dom_node`
is the method that returns the actual dom node where this instance of the component is mounted.

The `save!` line will trigger the save event in the parent component.  Notice that the method to trigger a custom event is the name of the event followed by a bang (!).

Finally we add the `blur` event handler and trigger our `cancel` event.

Now we can update our `TodoItem` component to be a little state machine, which will react to three events:  `double_click`, `save` and `cancel`.

```ruby
# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI) do
    if @editing
      EditItem(todo: @Todo)
      .on(:save, :cancel) { mutate @editing = false }
    else
      INPUT(type: :checkbox, checked: @Todo.completed)
      .on(:change) { @Todo.update(completed: !@Todo.completed) }
      LABEL { @Todo.title }
      .on(:double_click) { mutate @editing = true }
      A { ' -X-' }
      .on(:click) { @Todo.destroy }
    end
  end
end
```
All states in Hyperstack are simply Ruby instance variables (ivars).  Here we use the `@editing` ivar.

We have already used a lot of states that are built into the HyperModel and HyperRouter. The state machines in these complex objects are built out collections of instance variables like `@editing`.

In the `TodoItem` component the value of `@editing ...` controls whether to render the `EditItem` or the INPUT, LABEL, and Anchor tags.

Because `@editing` (like all ivars) starts off as nil, when the `TodoItem` first mounts, it renders the INPUT, LABEL, and Anchor tags.  Attached to the label tag is a `double_click` handler which does one thing:  *mutates* the component's state setting `@editing` to true.  This then causes the component to re-render, and now instead of the three tags, we will render the `EditItem` component.  

Attached to the `EditItem` component is the `save` and `cancel` handler (which is shared between the two events) that *mutates* the component's state, setting `@editing` back to false.

Using and changing state in a component is a simple as reading or changing the value of some instance variables.
The only caveat is that whenever you want to change a state variable whether its a simple assignment or changing the internal value of a complex structure like a hash or array you use the `mutate` method to signal Hyperstack that that state is changing.

### Chapter 10: Using EditItem to create new Todos

Our `EditItem` component has a good robust interface.  It takes a Todo, and lets the user edit the title, and then either save or cancel, using two custom events to communicate back outwards.

Because of this we can easily reuse `EditItem` to create new Todos.  Not only does this save us time, but it also insures that the user interface acts consistently.

Update the `Header` component to use `EditItem` like this:

```ruby
# app/hyperstack/components/header.
class Header < HyperComponent
  before_mount { @new_todo = Todo.new }
  render(HEADER) do
    EditItem(todo: @new_todo)
    .on(:save) { mutate @new_todo = Todo.new }
  end
end
```
What we have done is initialize an instance variable `@new_todo` to a new unsaved `Todo` item in the `before_mount` lifecycle method.  

Then we pass the value `@new_todo` to EditItem, and when it is saved, we generate another new Todo and save it in the `new_todo` state variable.

When `Header`'s state is mutated, it will cause a re-render of the Header, which will then pass the new value of `@new_todo`, to `EditItem`, causing that component to also re-render.  

We don't care if the user cancels the edit, so we simply don't provide a `:cancel` event handler.

Once the code is added a new input box will appear at the top of the window, and when you type enter a new Todo will be added to the list.

However you will notice that the value of new Todo input box does not clear.  This is subtle problem but it's easy to fix.

React treats the `INPUT` tag's `defaultValue` specially.  It is only read when the `INPUT` is first mounted, so it *does not react* to changes like normal
parameters.  Our `Header` component does pass in
new Todo records, but even though they are changing React *does not* update the INPUT.

React has a special param called `key`.  React uses this to uniquely identify mounted components.  It is used to keep track of lists of components,
it can also used in this case to indicate that the component needs to be remounted by changing the value of key.

All objects in Hyperstack respond to the `to_key` method which will return a suitable unique key id, so all we have to pass `@Todo` as the key param it
this will insure that as `@Todo` changes, we will re-initialize the `INPUT` tag.

```ruby
  ...
  INPUT(defaultValue: @Todo.title, key: @Todo) # add the special key param
  ...
```

### Chapter 11: Adding Styling

We are just going to steal the style sheet from the benchmark Todo app, and add it to our assets.

**Go grab the file in this repo here:** https://github.com/hyperstack-org/hyperstack/blob/edge/docs/tutorial/assets/todo.css
and copy it to a new file called `todo.css` in the `app/assets/stylesheets/` directory.

You will have to refresh the page after changing the style sheet.

Now its a matter of updating the css classes which are passed to components via the `class` parameter.

Let's start with the `App` component.  With styling it will look like this:

```ruby
# app/hyperstack/components/app.rb
class App < Hyperstack::Router
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
# app/hyperstack/components/footer.rb
class Footer < HyperComponent
  include Hyperstack::Router::Helpers
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
# app/hyperstack/components/index.rb
class Index < HyperComponent
  include Hyperstack::Router::Helpers
  render(SECTION, class: :main) do         # add class main
    UL(class: 'todo-list') do              # add class todo-list
      Todo.send(match.params[:scope]).each do |todo|
        TodoItem(todo: todo)
      end
    end
  end
end
```
For the EditItem component we want the parent to pass any html parameters such as `class` along to the INPUT tag.  We do this by adding the special
`others` param that will collect any extra params, we then pass it along in to the INPUT tag.  Hyperstack will take care of merging all the params
together sensibly.

```ruby
# app/hyperstack/components/edit_item.rb
class EditItem < HyperComponent
  param :todo
  triggers :save                             
  triggers :cancel    
  others   :etc  # can be named anything you want                       
  after_mount { DOM[dom_node].focus }        
  render do
    INPUT(@Etc, defaultValue: @Todo.title, key: @Todo)
    .on(:enter) do |evt|
      @Todo.update(title: evt.target.value)
      save!
    end
    .on(:blur) { cancel! }                   
  end
end
```
Now we can add classes to the TodoItem's list-item, input, anchor tags, and to the `EditItem` component:

```ruby
# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI, class: 'todo-item') do # add the todo-item class
    if @editing
      EditItem(class: :edit, todo: @Todo)  # add the edit class
      .on(:save, :cancel) { mutate @editing = false }
    else
      INPUT(type: :checkbox, class: :toggle, checked: @Todo.completed) # add the toggle class
      .on(:change) { @Todo.update(completed: !@Todo.completed) }
      LABEL { @Todo.title }
      .on(:double_click) { mutate @editing = true }
      A(class: :destroy) # add the destroy class and remove the -X- placeholder
      .on(:click) { @Todo.destroy }
    end
  end
end
```
In the Header we can send a different class to the `EditItem` component.  While we are at it
we will add the `H1 { 'todos' }` hero unit.

```ruby
# app/hyperstack/components/header.
class Header < HyperComponent
  before_mount { @new_todo = Todo.new }
  render(HEADER, class: :header) do                   # add the 'header' class
    H1 { 'todos' }                                    # Add the hero unit.
    EditItem(class: 'new-todo', todo: @new_todo) # add 'new-todo' class
    .on(:save) { mutate @new_todo = Todo.new }
  end
end
# app/hyperstack/components/header.
class Header < HyperComponent
  before_mount { @new_todo = Todo.new }
  render(HEADER) do
    EditItem(todo: @new_todo)
    .on(:save) { mutate @new_todo = Todo.new }
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
    INPUT(@Etc, placeholder: 'What is left to do today?',
                defaultValue: @Todo.title, key: @Todo)
    .on(:enter) do |evt| ...
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
Index:      10  
TodoItem:   16  
EditItem:   16  
Footer:     16  
Todo Model:  4  
Rails Route: 2  
--------------  
Total:      83  
```

The complete application is shown here:

```ruby
# app/hyperstack/components/app.rb
class App < HyperComponent
  include Hyperstack::Router
  render do
    SECTION(class: 'todo-app') do
      Header()
      Route('/', exact: true) { Redirect('/all') }
      Route('/:scope', mounts: Index)
      Footer() unless Todo.count.zero?
    end
  end
end

# app/hyperstack/components/header.
class Header < HyperComponent
  before_mount { @new_todo = Todo.new }
  render(HEADER, class: :header) do
    H1 { 'todos' }
    EditItem(class: 'new-todo', todo: @new_todo)
    .on(:save) { mutate @new_todo = Todo.new }
  end
end

# app/hyperstack/components/index.rb
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

# app/hyperstack/components/footer.rb
class Footer < HyperComponent
  include Hyperstack::Router::Helpers
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

# app/hyperstack/components/todo_item.rb
class TodoItem < HyperComponent
  param :todo
  render(LI, class: 'todo-item') do
    if @editing
      EditItem(class: :edit, todo: @Todo)  # add the edit class
      .on(:save, :cancel) { mutate @editing = false }
    else
      INPUT(type: :checkbox, class: :toggle, checked: @Todo.completed) # add the toggle class
      .on(:change) { @Todo.update(completed: !@Todo.completed) }
      LABEL { @Todo.title }
      .on(:double_click) { mutate @editing = true }
      A(class: :destroy) # add the destroy class and remove the -X- placeholder
      .on(:click) { @Todo.destroy }
    end
  end
end

# app/hyperstack/components/edit_item.rb
class EditItem < HyperComponent
  param :todo
  triggers :save
  triggers :cancel
  others   :etc
  after_mount { DOM[dom_node].focus }
  render do
    INPUT(@Etc, placeholder: 'What is left to do today?',
                defaultValue: @Todo.title, key: @Todo)
    .on(:enter) do |evt|
      @Todo.update(title: evt.target.value)
      save!
    end
    .on(:blur) { cancel! }
  end
end

# app/hyperstack/models/todo.rb
class Todo < ApplicationRecord
  scope :completed, -> () { where(completed: true)  }
  scope :active,    -> () { where(completed: false) }
end

# config/routes.rb
Rails.application.routes.draw do
  mount Hyperstack::Engine => '/hyperstack'
  get '/(*other)', to: 'hyperstack#app'
end
```

### General troubleshooting

1: Wait. On initial boot it can take several minutes to pre-compile all the system assets.  

2: Make sure to save (or better yet do a git commit) after every instruction so that you can backtrack

3: Its possible to get things so messed up the hot-reloader will not work.  Restart the server and reload the browser.

4: Reach out to us on Gitter, we are always happy to help get you onboarded!
