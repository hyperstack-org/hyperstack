#  ![](https://avatars3.githubusercontent.com/u/15810526?v=3&s=40&raw=true)HyperMesh


[![Join the chat at https://gitter.im/reactrb/chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/reactrb/chat?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Gem Version](https://badge.fury.io/rb/hyper-mesh.svg)](https://badge.fury.io/rb/hyper-mesh)

HyperMesh gives your HyperReact components CRUD access to your server side ActiveRecord models, using the the standard ActiveRecord API.
In addition HyperMesh implements push notifications (via a number of possible
technologies) so changes to records on the server are dynamically pushed to all authorised clients.

*Its Isomorphic Ruby in action.*

In other words one browser creates, updates, or destroys a model, and the changes are persisted in
active record models and then broadcast to all other authorised clients.

## Overview

+ HyperMesh is built on top of HyperReact.
+ HyperReact is a Ruby DSL (Domain Specific Language) to build [React.js](https://facebook.github.io/react/) UI components in Ruby.  As data changes on the client (either from user interactions or external events) HyperReact re-draws whatever parts of the display is needed.
+ HyperMesh provides a [flux dispatcher and data store](https://facebook.github.io/flux/docs/overview.html) backed by [Rails Active Record models](http://guides.rubyonrails.org/active_record_basics.html).  
You access your model data in your HyperReact components just like you would on the server or in an ERB or HAML view file.
+ If an optional push transport is connected HyperMesh broadcasts any changes made to your ActiveRecord models as they are persisted on the server.

For example consider a simple model called `Dictionary` which might be part of Wiktionary type app.

```ruby
class Dictionary < ActiveRecord::Base

  # attributes
  #   word: string
  #   definition: text
  #   pronunciation: string

  scope :defined, -> { 'definition IS NOT NULL AND pronunciation IS NOT NULL' }
end
```

Here is a very simple HyperReact component that shows a random word from the dictionary:

```ruby
class WordOfTheDay < React::Component::Base

  def pick_entry!  
    # pick a random word and assign the selected record to entry
    @entry = Dictionary.defined.all[rand(Dictionary.defined.count)]
    force_update! # redraw our component when the word changes
    # Notice that we use standard ActiveRecord constructs to select our
    # random entry value
  end

  # pick an initial entry before we mount our component...
  before_mount :pick_entry

  # Again in our render block we use the standard ActiveRecord API, such
  # as the 'defined' scope, and the 'word', 'pronunciation', and
  # 'definition' attribute getters.  
  render(DIV) do
    DIV { "total definitions: #{Dictionary.defined.count}" }
    DIV do
      DIV { @entry.word }
      DIV { @entry.pronunciation }
      DIV { @entry.definition }
      BUTTON { 'pick another' }.on(:click) { pick_entry! }
    end
  end
```    

## Basic Installation and Setup

The easiest way to install is to use the `hyper-rails` gem.

1. Add `gem 'hyper-rails'` to your Rails `Gemfile` development section.
2. Install the Gem: `bundle install`
3. Run the generator: `bundle exec rails g hyperloop:install --hyper-mesh` (or use `--all` to install all hyperloop gems)
4. Update the bundle: `bundle update`

You will find a `public` folder has been added to the `app/models` folder.  To access a model on the client, move it into the public directory.  If you are on Rails 5, you will also need to move the `application_record.rb` into the public directory.

You will also find an `app/policies` folder with a simple access policy suited for development.  Policies are how you will provide detailed access control to to your public models.  More details [here](/docs/authorization-policies.md).

Once you have run the hyperloop installer you can move models to the `app/models/public` directory and they will be accessible on both the server and client.

## Setting up the Push Transport

To have changes to your models on the server  broadcast to authorized clients, add a HyperMesh initializer file and specify a transport.  For example to setup a simple polled transport add this file:

```ruby
# config/initializers/hyper_mesh.rb
HyperMesh.configuration |config|
  config.transport = :simple_poller
end
```

After restarting, and reloading your browsers you will see changes broadcast to the clients.  You can also play with this by firing up a rails console, and creating, changing or destroying models at the console.

For setting up the other possible transports following one of these guides:

The easiest way to setup a true push transport is to use the Pusher-Fake gem.  Get started with this [guide.](docs/pusher_faker_quickstart.md)

or if you are already using Pusher follow this [guide.](docs/pusher_quickstart.md)

or if you are on Rails 5, and want to use ActionCable follow this [guide.](docs/action_cable_quickstart.md)

## Basic Configuration

For complete details on configuration settings go [here](/docs/configuration_details.md)

## ActiveRecord API

HyperMesh uses a large subset of the ActiveRecord API modified only when necessary to accommodate the asynchronous nature of the client.

See this [guide](/docs/activerecord_api.md) for details.

**Warning** currently the `attributes` method is supported, but please do not use it as some details of the semantics will be changing in an upcoming release.  Instead of `foo.attributes[:xyz]` use `foo.send('xyz')` for now.

## Client Side Scoping

By default scopes will be recalculated on the server.  To offload this to the client HyperMesh adds some features to the `ActiveRecord` `scope` method.  Details [here.](docs/client_side_scoping.md)  

## Authorization

Each application defines a number of *channels* and *authorization policies* for those channels and the data sent over the channels.

Policies are defined with *Policy* classes.  These are similar and compatible with [Pundit](https://github.com/elabs/pundit) but
you do not need to use the pundit gem (but can if you want.)

For complete details see [Authorization Policies](docs/authorization-policies.md)

## Common Errors

- No policy class:  
If you don't define a policy file, nothing will happen because nothing will get connected.  
By default HyperMesh will look for a `ApplicationPolicy` class.

- Wrong version of pusher-fake  (pusher-fake/base vs. pusher-fake/rspec)  
See the Pusher-Fake gem repo for details.

- Forgetting to add `require pusher` in application.js file  
this results in an error like this:
```text
Exception raised while rendering #<TopLevelRailsComponent:0x53e>
    ReferenceError: Pusher is not defined
```  
To resolve make sure you `require 'pusher'` in your application.js file if using pusher.

- No create/update/destroy policies
You must explicitly allow changes to the models to be made by the client. If you don't you will
see 500 responses from the server when you try to update.  To open all access do this in
your application policy: `allow_change(to: :all, on: [:create, :update, :destroy]) { true }`

- Cannot connect to real pusher account:  
If you are trying to use a real pusher account (not pusher-fake) but see errors like this  
```text
pusher.self.js?body=1:62 WebSocket connection to
'wss://127.0.0.1/app/PUSHER_API_KEY?protocol=7&client=js&version=3.0.0&flash=false'
failed: Error in connection establishment: net::ERR_CONNECTION_REFUSED
```
Check to see if you are including the pusher-fake gem.  
HyperMesh will always try to use pusher-fake if it sees the gem included.  Remove it and you should be good to go.  See [issue #5](https://github.com/hyper-react/HyperMesh/issues/5) for more details.

- Cannot connect with ActionCable.  Make sure that `config.action_cable.allowed_request_origins` includes the url you use for development (including the port) and that you are useing `Puma`.

- Attributes are not being converted from strings, or do not have their default values  
Eager loading is probably turned off.  HyperMesh needs to eager load `models/public` so it can find all the column information for all public models.

- When starting rails you get a message on the rails console `couldn't find file 'browser'`  
Hyper-React v0.10.0 removed the dependency on opal-browser.  You will have to add the 'opal-browser' gem to your Gemfile.

- On page load you get a message yacking about super class mismatch for `DummyValue`  
You are still have the old `reactive-record` gem in your Gemfile, remove it from your gemfile and your components.rb manifest.

- On page load you get a message yacking about no method `session` for `nil`  
You are still referencing the old reactive-ruby or reactrb gems either directly or indirectly though a gem like reactrb-router.  Replace any gems like
`reactrb-router` with `hyper-router`.  You can also just remove `reactrb`, as `hyper-react` will be included by the `hyper-mesh` gem.

## Debugging

Sometimes you need to figure out what connections are available, or what attributes are readable etc.

Its all to do with your policies, but perhaps you just need a little investigation.

You can bring up a console within the controller context by browsing `localhost:3000/rr/console`

*Note:  change `rr` to wherever you are mounting reactive record in your routes file.*

*Note: in rails 4, you will need to add the gem 'web-console' to your development section*

Within the context you have access to `session.id` and current `acting_user` which you will need, plus some helper methods to reduce typing

- Getting auto connection channels:  
`channels(session_id = session.id, user = acting_user)`  
e.g. `channels` returns all channels connecting to this session and user  
providing nil as the acting_user will test if connections can be made without there being a logged in user.

- Can a specific class connection be made:
`can_connect?(channel, user = acting_user)`
e.g. `can_connect? Todo`  returns true if current acting_user can connect to the Todo class  
You can also provide the class name as a string.

- Can a specific instance connection be made:
`can_connect?(channel, user = acting_user)`
e.g. `can_connect? Todo.first`  returns true if current acting_user can connect to the first Todo model.  
You can also provide the instance in the form 'Todo-123'

- What attributes are accessible for a model instance:  
`viewable_attributes(instance, user = acting_user)`

- Can the attribute be viewed:  
`view_permitted?(instance, attribute, user = acting_user)`

- Can a model be created/updated/destroyed:
`create_permitted?(instance, user = acting_user)`  
e.g. `create_permitted?(Todo.new, nil)` can anybody save a new todo?  
e.g. `destroy_permitted?(Todo.last)` can the acting_user destroy the last Todo

You can of course simulate server side changes to your models through this console like any other console.  For example

`Todo.new.save` will broadcast the changes to the Todo model to any authorized channels.

## Development

The original `ReactiveRecord` specs were written in opal-rspec.  These are being migrated to
use server rspec with isomorphic helpers.  There are about 170 of the original tests left and to run these you

1. cd to `reactive_record_spec/test_app`
2. do a bundle install/update as needed,
3. `rake db:reset db:test:prepare`,
4. start the server: `bundle exec rails s`,
5. then visit `localhost:3000/spec-opal`.

If you want to help **PLEASE** consider spending an hour and migrate a spec file to the new format.  You can
find examples by looking in the `spec/reactive_record/` directory and matching to the original file in
`reactive_record_test_app/spec_dont_run/moved_to_main_spec_dir`

The remaining tests are run in the more traditional `bundle exec rake`

or

```
bundle exec rspec spec
```

You can run the specs in firefox by adding `DRIVER=ff` (best for debugging.)  You can add `SHOW_LOGS=true` if running in poltergeist (the default) to see what is going on, but ff is a lot better for debug.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reactive-ruby/HyperMesh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
