## Upgrade Instructions - Part I

### 1. Update your gemfile

```ruby
gem 'rails-hyperstack', '~> 1.0.alpha1.5'
gem 'hyper-spec', '~> 1.0.alpha1.5'  # if using hyper-spec
```

remove any references to hotloader stuff from the gemfile, as well as opal-jquery, and hyper-react
(these will all be brought in as needed by rails-hyperstack)


### 2. Move `app/hyperloop` directory to `app/hyperstack`

the internal directories can remain (i.e. components, models, etc)

### 2. Rename `app/hyperstack/component.rb` file.

rename it to component.rbx  it is no longer used, but you might want to keep it just in case instead of deleting.

Renaming it to .rbx will effectively remove it, without deleting it.

### 3. Double check `application_record.rb` files are correct.

Your main definition of `ApplicationRecord` should be in `app/hyperstack/models/application_record.rb`

Meanwhile the contents of `app/models/application_record.rb` should look like this:

```ruby
# app/models/application_record.rb
# the presence of this file prevents rails migrations from recreating application_record.rb
# see https://github.com/rails/rails/issues/29407

require 'models/application_record.rb'
```

### 4. Change the component base class from `Hyperloop::Component` to `HyperComponent`

Hyperstack now follows the Rails convention used by ApplicationRecord and ApplicationController
of having an application defined base class. 

Create a `app/hyperstack/components/hyper_component.rb` base class:

```ruby
# app/hyperstack/components/hyper_component.rb
class HyperComponent
  def self.inherited(child)
    child.include Hyperstack::Component
    child.param_accessor_style :legacy       # use the hyperloop legacy style param accessors
    child.include Hyperstack::Legacy::Store  # use the legacy state definitions, etc.
  end
end
```

Now  global search and replace all references in the `app/hyperstack/components` directory from `Hyperloop::Component` to `HyperComponent`

### 5. Update app/assets/javascript/application.js

The last lines of `app/assets/javascripts/application.js` should look like this:

```javascript
//= require hyperstack-loader
//= require_tree .  
```

If you are not using require_tree, then the hyperstack-loader require should be towards the bottom, you might have to play with the position to get it right, but basically it should be the last thing required before you get into your application specific requires that are in the `app/assets/javascript` directory.

remove any references to react, react_ujs, hotloader, opal, opal-jquery, and hyperloop-loader, this is all now handled by hyperstack-loader

### 6. Update items related to Hotloader

If you are using the hot loader, and foreman (i.e you have a Procfile) then your procfile will look like this:
```text
# Procfile
web: bundle exec rails s -p 3004 -b 0.0.0.0
hot: bundle exec hyperstack-hotloader -p 25223 -d app/hyperstack/
```

The hotloader gem itself should be removed from the gemfile.

In the hyperstack initializer there should be this line:  
```ruby
  Hyperstack.import 'hyperstack/hotloader', 'client_only: true if Rails.env.development?'
```

remove any  other references to hotloader in the initializer, and in `app/assets/javascripts/application.js`

### 7. Update the initializer

Rename `config/initializers/hyperloop.rb` to `config/initializers/hyperstack.rb`

The initializer will look like this... comment/uncomment as needed:

```ruby
# comment next line out if NOT using webpacker
Hyperstack.cancel_import 'react/react-source-browser' # bring your own React and ReactRouter via Yarn/Webpacker
# uncomment next line if using hotloader
# Hyperstack.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
# set the component base class

Hyperstack.component_base_class = 'HyperComponent' # i.e. 'ApplicationComponent'

# prerendering is default :off, you should wait until your
# application is relatively well debugged before turning on.

Hyperstack.prerendering = :off # or :on

# transport controls how push (websocket) communications are
# implemented.  The default is :action_cable.
# Other possibilities are :pusher (see www.pusher.com) or
# :simple_poller which is sometimes handy during system debug.

Hyperstack.transport = :action_cable # or :none, :pusher,  :simple_poller

# add this line if you need jQuery
Hyperstack.import 'hyperstack/component/jquery', client_only: true

# change definition of on_error to control how errors such as validation
# exceptions are reported on the server
module Hyperstack
  def self.on_error(operation, err, params, formatted_error_message)
    ::Rails.logger.debug(
      "#{formatted_error_message}\n\n" +
      Pastel.new.red(
        'To further investigate you may want to add a debugging '\
        'breakpoint to the on_error method in config/initializers/hyperstack.rb'
      )
    )
  end
end if Rails.env.development?
```

### 8. Change Element to jQ

If you are using jQuery, you will have things like `Element['#some-id'].focus()` etc.
These need to change to `jQ[...].focus()` etc.

Use CASE SENSITIVE global search and replace.


### 9. `IsomorphicHelpers` changes to `Hyperstack::Component::IsomorphicHelpers`

search and replace...

### 10. Stores 

To use legacy store behavior you can include the `Hyperstack::Legacy::Store` mixin, in your stores.

You do not need to subclass the stores.  However if you have a lot of stores, you could create a base class like this:

```ruby
# app/hyperstack/stores/hyper_store.rb
class HyperStore
  include Hyperstack::Legacy::Store
end
```

and then subclass off of Hyperstore.

You will also need to add this to your Gemfile:

```ruby
gem 'hyper-store`, '~> 1.0.alpha1.5'
```

### 10. Change name of Hyperloop::... to Hyperstack::

Hyperloop::Operation -> Hyperstack::Operation
Hyperloop::Store -> 

If at this point you have other classes and methods under the `Hyperloop` namespace, you will have to find
the equivilent class or method under Hyperstack.  Its going to be a case by case basis.  Let us know if you need help, and we can 
add each case to this document.

### 11. Remove any patches

If you have any patches to Hyperloop modules or classes, you probably don't need (or want them any more)

## Upgrade Instructions Part II

Once your app is working on the latest Hyperstack, you will want to upgrade to the latest Hyperstack syntax.  This can be done gradually

### 1. Tag names

Tag names should all be upcased.  i.e. `DIV`, `UL`, `LI`, `SPAN` etc.  The lower case syntax is deprecated so this should be updated.

### 2. Param accessors

The legacy syntax to access params was `params.foo`.   The standard approach now is to just to use `foo`.

To change this you will need to change `param_accessor_style :legacy` to `param_accessor_style :accessor` in your `HyperComponent` definition.

Then you should be able to do a global search and delete in the component directory of `params.`.

### 3. State definition mutators, and accessors.

State is now represented by instance variables.  No special syntax is needed to declare a state variable.

To access a state variable local to a component all you need to do is read the instance variable in the usual way.

To update the state variable (or its contents) you prefix the operation with the mutate method.

For example `mutate @foo[:bar] = 12` would mutate a hash named @foo.

Once all your state accessors are updated you can remove the 

```ruby
    child.include Hyperstack::Legacy::Store  # use the legacy state definitions, etc.
```

from your `HyperComponent` base class.

### 4. Other legacy behaviors

Should be flagged by warnings in console.log.  Update as instructed.

