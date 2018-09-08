# Models

Much like Stores, Models hold state which Components watch and re-render when the data changes. The key difference between Models and Stores, however, is that Models are an extension of your server side (Rails) Active Record models. Changes made on the server are pushed to the connected clients who's Components are rendering that data.

Components, Operations and Stores have no backend dependancy, but Models and Policies are integrated with Rails and require a Rails backend.

ActiveRecord-like Models are accessible in your isomorphic code. Models are an Isomorphic ActiveRecord wrapper for Hyperloop.

You access your Models as simply as this:

```ruby
class BookList < Hyperloop::Component

  render(UL) do
    Book.all.each do |book|
      LI { "#{book.name}" }
    end
  end
end
```

There are a few important things to notice:

+ Firstly let's discuss what's missing - there is no API, no Controllers - no boiler-plate code whose purpose if simply to transfer data from the server to the client.
+  You have full access to your ActiveRecord Models in your client side code as if you were accessing them inside an ERB file.
+ With pre-rendering, the page is rendered by the server before being delivered to the client. This rendering process uses ActiveRecord in exactly the same way as rendering an ERB file would do.
+ The key difference is that the same code will run in the browser, the same simple Ruby code will be compiled into JavaScript and Hyperloop will provide all the infrastructure necessary to query the server and deliver the data to the client.

**No boilerplate API, no serialisation, no de-serialisation.** Much like Relay and GraphQL, when rendering, Hyperloop parses through each Component and establishes which fields are necessary then queries just for those fields which are returned as JSON and then inserted into each Component. The key difference with Relay is that both the client and server code is provided by Hyperloop so the entire process is seamless for the developer.

### CRUD Access

Hyperloop provides full CRUD access to your ActiveRecord models.

The save method works like ActiveRecord save, except it returns a promise that is resolved when the save completes (or fails.)

```ruby
my_todo.save(validate: false).then do |result|
  # result is a hash with {success: ..., message: , models: ....}
end
```

You govern access through Policy which we will cover in the next chapter.

### Push Notifications

Changes made to Models on a client or server are automatically synchronized to all other authorized connected clients using ActionCable, pusher.com or polling. The synchronization is completely automatic and magical to behold and not something we can demonstrate in this introduction - you will need to see it to believe it.

### How it works

Components read Stores and Models in order to display data. If during the rendering of the Component the Model data is not yet loaded, placeholder values (the default values from the columns_hash) will be returned to the Component.

Hyperloop then keeps track of where these placeholders (or DummyValues) are displayed, compiles a request to send to the server which is then read from the database and returned as JSON and the Components are re-rendered with the correct data.

If later the data changes (either due to local user actions, or receiving push updates) then again any parts of the display that were dependent on the current values will be re-rendered.

You normally do not have to be aware of this. Just access your Models using the normal scopes and finders, then compute values and display attributes as you would on the server. Initially, the display will show the placeholder values and then will be replaced with the real values.

-----------------------------------

Next, we are going to look at Operations. If you accept that your Store's and Model's job is to keep state and share it with the Components, an Operations's job is to mutate (change) state.

Operations are where your business logic lives, your procedures that mutate state and data.
