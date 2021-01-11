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

hyperstack-config seems to be upgraded to use this method but unless there is some trick it will fail if running on Opal 0.11.  See hyper-state's test-app app/assets/application.js file for a way to make a switch, but perhaps hyperstack-config does this by redefining Opal.loaded?

------------

@@vars:  Are now implemented correctly (I guess) so that they are lexically scoped, thus this does not work:

```
Foo.class_eval do
  def self.get_error
    @@error
  end
end
```
-------------

opal-browser not released for opal 1.0 yet, causing deprecation warnings.  hyper-component loads opal-browser from master so that spec ./spec/client_features/component_spec.rb:499 can pass, but we at least need a note on how to get rid of these warnings (get opal-browser from master) until opal-browser is released.

------------

This code will no longer work as expected:

```ruby
x = `{}`
"foo(#{x})"  # <- generates "foo("+x+")" which results in the following string "foo([Object Object])"
```
not sure how this worked before, but it did.

------------

array.each do |e|
  # be careful any values e that are `null` will get rewritten as `nil` fine I guess most of the time
  # but caused some problems in specs where we are explicitly trying to iterate over JS values
  # see /spec/client_features/component_spec.rb:656


------------
  search around for references to config.react.server_renderer_options and/or "server_rendering.js"
  inconsistent... should now default to hyperstack_prerender_loader.js
  and more over there is a hyperstack option as well, so the server_renderer file option should match
------------

Opal splat works properly in 1.0!  

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

Can't inherit directly from ApplicationController::Base in Rails 6.0 ...


MEANWHILE REMEMBER - to pull in next-gen-hyperspec branch
AND figure out how to make libv8 dependency optional


Progress:

hyper-spec: Still needs to be merged with the next gen branch  (note have to include a patch the selenium-webdriver in hyper-spec.  Investigate why we are dependent on an old version?)
(the rest of these are passing using current hyper-spec syntax)
hyperstack-config: passing
hyper-state: passing
hyper-component: need to get error logs (see spec_helper line 43) plus plenty of other failures.
