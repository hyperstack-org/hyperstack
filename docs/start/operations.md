# Operations

THESE DOCS NEED UPDATING WITH THE NEW DSL

Operations are the engine rooms of Hyperloop, they orchestrate the interactions between Components, external services, Models and Stores. **Operations are where your business logic lives.**

In a traditional MCV architecture, there is no defined place to keep business logic. You can overload your Controllers, Views or Models and (unless you follow a defined pattern like Trailblazer) you generally end up with your business logic all over the place. Our vision of building a 'Complete Ruby Isomorphic Framework' meant that we had to address that problem head on, so we created Operations.

The design of our Operations has been inspired by a few sources:

+ We liked the way the [Mutations Gem](https://github.com/cypriss/mutations) handles parameters and validation
+ [Trailblazer](https://github.com/trailblazer/trailblazer#operation) inspired the idea of Operations and we like the `validate` and `step` methods
+ The [Flux](https://facebook.github.io/flux/) pattern taught us that unidirectional data flow is a good idea and Stores should be able to `receive` dispatches from Operations

**Operations execute on the clients or the server.** This simple principal radically simplifies application design and testing.

Hyperloop Operations work in three ways:

1. They `run` a sequence of `steps`. Each step is a progressive step in a workflow, only continuing to the next step if the current step succeeds. This mode borrows from Trailblazer's concept of an Operation.
2. Much like Flux Actions, Stores can `receive` Operations so a Store can watch for an Operation being dispatched and act accordingly. This shifts the responsibility to the Store mutate its state when an Operation is dispatched.
3. `ServerOps` are Operations which, to your Isomorphic code, look like normal Operations but are guaranteed to only run on the server, even when they are invoked from the client. A good reason for this type of Operation would be when resources needed by the Operation are bound to the server - for example invoking a Mailer or updating a database. ServerOps do away with the need for a boilerplate API layer (unless you specifically want an API).

### Operations with Steps

Stores hold state and Operations orchestrate the mutation of state. In the Store chapter, we demonstrated how a class method on the Store could be used to mutate the state. In this example, we will have an Operation mutate the Store's state instead:

```ruby runable
class Discounter < Hyperloop::Store
   state discount: 30, scope: :class, reader: true
   state tries: 0, scope: :class, reader: true

  def self.lucky_dip!
    mutate.discount( state.discount + rand(-5..5) )
    mutate.tries(state.tries + 1)
  end

  class LuckyDipOp < Hyperloop::Operation
    def check_tries
      puts Discounter.tries
      abort! if Discounter.tries > 2
    end
    step { check_tries }
    step { Discounter.lucky_dip! }
  end
end

class OfferLuckyDip < Hyperloop::Component

  render(DIV) do
    H1 {"Your discount is #{Discounter.discount}%"}
    BUTTON { "Lucky Dip" }.on(:click) do
      Discounter.LuckyDipOp
    end
  end
end
```

You will notice in the code above:

+ This approach is very similar to simply adding a method to the Store to mutate the state, but there are some advantages. Firstly, we can take advantage of the validation of incoming params and secondly we can use `step`'s to ensure that each part of the operation only executes if the previous part was successful. Notice how we called `abort!` to stop the Operation.
+ The LuckyDipOp Operation is included in the Store's namespace. This is optional but a good way to group Operations with the Stores they operate on.

### Dispatchers and Receivers

Next, let's look at an Operation that follows the dispatch and receiver (Flux) pattern.

This little example Operation will dispatch a message that a Store will receive. We have implemented the Flux pattern into Operations and Stores where Operations are dispatchers and Stores are receivers.

**All Operations dispatch but it up to a Store to receive a dispatch.**

```ruby
class Logout < Hyperloop::Operation
  # do the actual logout
end

class NavBarStore < Hyperloop::Store
  state user_name: "Fred", scope: :class, reader: true

  receives Logout do
    # this Store is listening for Logout
    mutate.user_name "No user"
  end
end

class UserPage < Hyperloop::Component
  render(DIV) do
    P { "Current user: #{NavBarStore.user_name}" }
    BUTTON { "Logout" }.on(:click) do
      Logout.run
    end
  end
end
```

In the code above, you will notice that the Logout Operation does not specifically interact with the NavBarStore Store, but the Store receives the Operation when it is dispatched.

### Server Operations

There are some Operations that simply do not make sense to run on the client as the resources they depend on may not be available on the client. For example, consider an Operation that needs to send an email - there is no mailer on the client so the Operation has to execute from the server.

That said, with our highest goal being developer productivity, it should be as invisible as possible to the developer where the Operation will execute. To complete the example, a developer writing front-end code should be able to invoke a server-side resource (like a mailer) just as easily as they might invoke a client-side resource.

In some cases there might be Operation logic that you want to ensure always runs on the server, as per the example below:

```ruby
class ValidateUserCredentials < Hyperloop::ServerOp
  param :acting_user
  add_error :acting_user, :no_valid_default_cc, "No valid default credit card" do
    !params.acting_user.has_default_cc?
  end
end
```

**ServerOps execute only on the server but are invokable from your Isomorphic code** No need for boilerplate APIs just to execute a server side Operation. ServerOps are just like any normal Operations and invokable from any part of your code.

You can also broadcast the dispatch from Server Operations to all authorized clients. The `dispatch_to` method will determine a list of channels to broadcast the dispatch to:

```ruby
class Announcement < Hyperloop::ServerOp
  # no acting_user because we don't want clients to invoke the Operation
  param :message
  param :duration, type: Float, nils: true
  # dispatch to the builtin Hyperloop::Application Channel
  dispatch_to Hyperloop::Application
end

class CurrentAnnouncements < Hyperloop::Store
  state_reader all: [], scope: :class
  receives Announcement do
    mutate.all << params.message
    after(params.duration) { delete params.message } if params.duration
  end
  def self.delete(message)
    mutate.all.delete message
  end
end
```
