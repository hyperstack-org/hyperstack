## Upgrade Instructions - Part I

### 1. Update your gemfile

```ruby
gem 'rails-hyperstack', '~> 1.0.alpha1.5'
gem 'hyper-spec', '~> 1.0.alpha1.5'  # if using hyper-spec
```

remove any references to hotloader stuff.

### 2. Move `app/hyperloop` directory to `app/hyperstack`

the internal directories can remain (i.e. components, models, etc)

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

Now  global search and replace all references to `Hyperloop::Component` to `HyperComponent`

### 5. Update app/assets/javascript/application.js

The last lines of `app/assets/javascripts/application.js` should look like this:

```javascript
//= require hyperstack-loader
//= require_tree .
```

Note: remove any lines mentioning hotloader.

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

### 8. Change Element to jQ

If you are using jQuery, you will have things like `Element['#some-id'].focus()` etc.
These need to change to `jQ[...].focus()` etc.

### 9. `IsomorphicHelpers` changes to `Hyperstack::Component::IsomorphicHelpers`

search and replace...

### 10. Change name of Hyperloop::... to Hyperstack::

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

