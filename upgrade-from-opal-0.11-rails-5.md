### Progress:

+ hyper-spec: passing
+ hyperstack-config: passing
+ hyper-state: passing
+ hyper-store: passing
+ hyper-router: passing
+ hyper-component: passing
+ hyper-operation: passing
+ hyper-model: first couple of specs pass, suspect more issues because splat operator is now working properly.
---
### Multiple Dependency Environments Supported

set env OPAL_VERSION='~ > 0.11' (for example) and then bundle update  
set env RAILS_VERSION='~> 5.0' (for example) and then bundle update

note that when testing hyper-component with OPAL_VERSION 0.11 you must also set the environment
variable to the same when running the specs (because we DONT want to fetch opal-browser from github see below)

note that Opal 0.11 will NOT work with rails 6.x, so that leaves three test environments
1. no specification = latest opal (1.x) and latest rails (6.x)
2. OPAL_VERSION='~> 0.11' = opal 0.11 and forces rails 5.x
3. RAILS_VERSION='~> 5.0' = rails 5.x and defaults to latest opal (1.0)
---
### Opal require implementation changed

replace

```javascript
Opal.load('xxxx')
```
with
```javascript
Opal.loaded(OpalLoaded || []);
Opal.require("components");
```

`require 'opal'` must be executed before any ruby code (including other requires.)  This was not true in Opal 0.11

hyperstack-config semantically figures out the right method, so if you use hyperstack-config consistently to load the opal code, all will be well!

Typically:

+ app/assets/javascript/application.js  
should have the line:  
`//= require hyperstack-loader`
+ add remove other dependencies using Hyperstack.import

---

### @@vars properly implemented

@@vars:  Are now implemented correctly (I guess) so that they are lexically scoped, thus this does **not** work:

```
Foo.class_eval do
  def self.get_error
    @@error
  end
end
```
because its lexically scoped, the compiler looks for an inclosing class definition for @@foo, not what you want.

in this case simply replace `Foo.class_eval do` with `class Foo`

---
### opal-browser must be taken from master to work with 1.0

opal-browser not released for opal 1.0 yet, causing deprecation warnings.  To work around this we include browser in the hypercomponent Gemfile (not gemspec) unless the OPAL_VERSION environment variable is set to 0.11

TODO: Release opal-browser!

------------

### compiler checks for JS undefined, empty objects, and null in more places

This code will no longer work as expected:

```ruby
x = `{}`
"foo(#{x})"  # <- generates "foo("+x+")" which
# results in the following string "foo([Object Object])"
```
not sure how this worked before, but it did.

```ruby
array.each do |e|
  # be careful any values e that are `null` will
  # get rewritten as `nil` fine I guess most of the time
  # but caused some problems in specs where we are
  # explicitly trying to iterate over JS values
  # see /spec/client_features/component_spec.rb:656
```

------------

### back quotes operator now works properly in hyper-spec blocks

This now works properly:

```ruby
  evaluate_ruby do
    ...
    foo = `JSON.stringify(x)`
    ...
  end
```

------------

### TODO: inconsistent dependency on server_rendering.js

  search around for references to config.react.server_renderer_options and/or "server_rendering.js"
  inconsistent... should now default to hyperstack_prerender_loader.js
  and more over there is a hyperstack option as well, so the server_renderer file option should match

------------

### Opal splat works properly in 1.0!  

```ruby
foo(*[1, 2], [[3, 4]])

def foo(*x)
  # 0.9 x == [1, 2, [3, 4]]
  # 1.0 x == [1, 2, [[3, 4]]]
end
```

is there a fix that works for both 1.0 and 0.9 ? or do we need a SWITCH???

Found this first in hyper-model, so in hyper-model
these are going to be marked with # SPLAT BUG with the old code until things get sorted

------------

### Can't inherit directly from ApplicationController::Base in Rails 6.0 ...

------------

### TODO pull in next-gen-hyperspec branch

------------

### TODO figure out how to make libv8 dependency optional

-----------

### Patch selenium webdriver

Hyper-spec currently depends on an older version of selenium webdriver, and so requires this patch be applied to get logging to work:

```ruby
module Selenium
  module WebDriver
    module Chrome
      module Bridge
        COMMANDS = remove_const(:COMMANDS).dup
        COMMANDS[:get_log] = [:post, 'session/:session_id/log']
        COMMANDS.freeze

        def log(type)
          data = execute :get_log, {}, {type: type.to_s}

          Array(data).map do |l|
            begin
              LogEntry.new l.fetch('level', 'UNKNOWN'), l.fetch('timestamp'), l.fetch('message')
            rescue KeyError
              next
            end
          end
        end
      end
    end
  end
end
```

TODO: figure out if we have to depend on this old version

---
