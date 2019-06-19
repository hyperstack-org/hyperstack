# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0alpha1.5 - 2019-06-19
### Security
+ [#165](https://github.com/hyperstack-org/hyperstack/issues/165) Secure access to `composed_of` relationships.

### Added
+ [#114](https://github.com/hyperstack-org/hyperstack/issues/114) Add Polymorphic Models
+ [#186](https://github.com/hyperstack-org/hyperstack/issues/186) Allow components to override built-in event names (i.e. `fires :click`)
+ [#185](https://github.com/hyperstack-org/hyperstack/issues/185) Allow import of es6 modules that have a single component
+ [#183](https://github.com/hyperstack-org/hyperstack/issues/183) Add new Rails 6 active support methods: `extract!` and `index_with`
+ [#180](https://github.com/hyperstack-org/hyperstack/issues/180) `sleep` now returns a promise so it works nicely with Operations
+ [#176](https://github.com/hyperstack-org/hyperstack/issues/176) The `render` callback is now optional.  See issue for details.
+ [#168](https://github.com/hyperstack-org/hyperstack/issues/168) Allow custom headers in `ServerOp`s
+ [#160](https://github.com/hyperstack-org/hyperstack/issues/160) Allows for dynamically attaching events: `.on(false || nil)` is ignored.  
+ [#159](https://github.com/hyperstack-org/hyperstack/issues/159) Hyperstack.connect behaves nicely if passed a dummy value.
+ [#148](https://github.com/hyperstack-org/hyperstack/issues/148) Rails installer works with existing Rails apps.
+ [#146](https://github.com/hyperstack-org/hyperstack/issues/146) Allow ActiveModel attribute methods to be overridden.


### Fixed
+ [#196](https://github.com/hyperstack-org/hyperstack/issues/196) The `empty?` method no longer forces fetch of entire collection
+ [#195](https://github.com/hyperstack-org/hyperstack/issues/195) UI will not update until after all relationships of a destroyed record are completely updated.
+ [#194](https://github.com/hyperstack-org/hyperstack/issues/194) Fetching STI models via scope and finder will now return the same backing record.
+ [#193](https://github.com/hyperstack-org/hyperstack/issues/193) Allow the `super` method in hyper-spec examples.
+ [#192](https://github.com/hyperstack-org/hyperstack/issues/192) Dummy values will be initialized with schema default value.
+ [#191](https://github.com/hyperstack-org/hyperstack/issues/191) Fixed incompatibility between the Router and Legacy style param method.
+ [#181](https://github.com/hyperstack-org/hyperstack/issues/181) Fixed nested class component lookup.
+ [#179](https://github.com/hyperstack-org/hyperstack/issues/179) Once an operation moves to the failed track it now stays on the failed track.
+ [#178](https://github.com/hyperstack-org/hyperstack/issues/178) Resetting system now correctly reinitializes all variables.
+ [#173](https://github.com/hyperstack-org/hyperstack/issues/173) Both sides of a relationship can be new and will get saved properly.
+ [#170](https://github.com/hyperstack-org/hyperstack/issues/170) HyperSpec `pause` method working again.
+ [#169](https://github.com/hyperstack-org/hyperstack/issues/169) Fixes to ActiveRecord model equality test.
+ [#166](https://github.com/hyperstack-org/hyperstack/issues/166) Allow `Element#dom_node` to work with native components.
+ [#164](https://github.com/hyperstack-org/hyperstack/issues/164) Insure state change notification when scopes change remotely.
+ [#163](https://github.com/hyperstack-org/hyperstack/issues/163) Ignore hotloader and hotloader errors during prerendering.
+ [#154](https://github.com/hyperstack-org/hyperstack/issues/154) Stop raising deprecation notices when using `imports` directive.
+ [#153](https://github.com/hyperstack-org/hyperstack/issues/153) `.to_n` working properly on Component classes.
+ [#144](https://github.com/hyperstack-org/hyperstack/issues/144) Timeout if connection between console and server fails.
+ [#143](https://github.com/hyperstack-org/hyperstack/issues/143) `Errors#full_messages` working properly.
+ [#138](https://github.com/hyperstack-org/hyperstack/issues/138) Count of has_many :through relations working properly
+ [#126](https://github.com/hyperstack-org/hyperstack/issues/126) Scopes no longer returning extra `DummyValue`.
+ [#125](https://github.com/hyperstack-org/hyperstack/issues/125) Belongs-to relationships on new records will react to updates to the relationship.
+ [#120](https://github.com/hyperstack-org/hyperstack/issues/120) `ActiveRecord::Base.new?` renamed to `new_record?` (you can still use `new?` or override it)


## 1.4alpha - 2019-02-15
### Security
+ [#117](https://github.com/hyperstack-org/hyperstack/issues/117) Finder methods will return nil instead of raising access violations.

### Added
+ [#120](https://github.com/hyperstack-org/hyperstack/issues/120) Alias `ActiveRecord::Base#new_record?` to `#new?`.
+ [#111](https://github.com/hyperstack-org/hyperstack/issues/111) Add #ref method to Element class
+ [#112](https://github.com/hyperstack-org/hyperstack/issues/112) Add `:init` param to `INPUT`, `SELECT`, and `TEXTAREA` tags.

### Fixed
+ [#128](https://github.com/hyperstack-org/hyperstack/issues/128) Hyperspec improperly parses block parameters
+ [#113](https://github.com/hyperstack-org/hyperstack/issues/113) Can't use finder methods on a scope
+ [#110](https://github.com/hyperstack-org/hyperstack/issues/128) Mutate is executing AFTER render cycle completes causing issues with controlled inputs


## 1.3alpha - 2019-01-16
### Security  
+ [#102](https://github.com/hyperstack-org/hyperstack/issues/102) Security hole in find_record method filled.

### Added
+ [#62](https://github.com/hyperstack-org/hyperstack/issues/62) `set_jq` method to capture element ref as a jQuery object
+ [#70](https://github.com/hyperstack-org/hyperstack/issues/70) New syntax and implementation for "while loading".
+ [#72](https://github.com/hyperstack-org/hyperstack/issues/72) Event handlers (i.e. `on(:click)`) can be specified at the component class level.
+ [#73](https://github.com/hyperstack-org/hyperstack/issues/73) `before_render` (runs before mounting & before updating) and  `after_render` (runs after_mounting & after_updating)  
+ [#74](https://github.com/hyperstack-org/hyperstack/issues/74) Alternative `param_accessor_style :accessors` option: Creates an instance method for each param.  I.e. `param :foo` will add a `foo` method to the component.  
+ [#77](https://github.com/hyperstack-org/hyperstack/issues/77) Ruby like `rescues` component call back.  Define error handling at the component level - uses react error boundries under the hood.
+ [#85](https://github.com/hyperstack-org/hyperstack/issues/85) Add `pluralize` method to component.  Works like Rails `pluralize` view helper.
+ [#89](https://github.com/hyperstack-org/hyperstack/issues/89) Automatically create ActiveRecord inverse relationships as needed.  Previously both sides of the relationship had to be declared.
+ [#90](https://github.com/hyperstack-org/hyperstack/issues/90) Automatically load `config/initializers/inflections.rb` if present
+ [#99](https://github.com/hyperstack-org/hyperstack/issues/99) Better diagnostics for server access violations and other errors
+ [#94](https://github.com/hyperstack-org/hyperstack/issues/94) `Hyperstack.anti_csrf_token` returns the stack specific anti_csrf_token.

### Changed
+ [#62](https://github.com/hyperstack-org/hyperstack/issues/62) jQuery now accessed by global `jQ` method (replacing `DOM` class)
+ [#68](https://github.com/hyperstack-org/hyperstack/issues/68) Renamed `before_receives_props` to `before_new_params`
+ [#91](https://github.com/hyperstack-org/hyperstack/issues/91) Rename `triggers` to `fires`

### Deprecated
+ [#70](https://github.com/hyperstack-org/hyperstack/issues/70) Deprecated original `while_loading` method in favor of the `WhileLoading` mixin.

### Fixed
+ [#106](https://github.com/hyperstack-org/hyperstack/issues/106) updated unparser, mini-racer and libv8 versions
+ [#76](https://github.com/hyperstack-org/hyperstack/issues/76) Regression: Hotloader was not remounting lifecycle hooks.
+ [#59](https://github.com/hyperstack-org/hyperstack/issues/59) Component built in event names (i.e. `click`) were not working with `triggers` (aka `fires`) macro.
+ [#63](https://github.com/hyperstack-org/hyperstack/issues/63) Could not pass a component class as a param.
+ [#64](https://github.com/hyperstack-org/hyperstack/issues/64) Router's render method would not accept a simple string.
+ [#65](https://github.com/hyperstack-org/hyperstack/issues/65) `observe` and `mutate` Observer methods were returning nil.
+ [#67](https://github.com/hyperstack-org/hyperstack/issues/67) Hyper Model: `while_loading` was not working with loading scopes.  This is is also working properly with the new `WhileLoading` mixin.
+ [#75](https://github.com/hyperstack-org/hyperstack/issues/75) Router `redirect` was not working in prerendering.
+ [#78](https://github.com/hyperstack-org/hyperstack/issues/78) Hyper Model: client scope optimization was not working if `all` scope is dummy or unknown.
+ [#79](https://github.com/hyperstack-org/hyperstack/issues/79) Hyper Model: `count` of scope was unnecessarily replaced with a dummy "1".
+ [#81](https://github.com/hyperstack-org/hyperstack/issues/81) Hyper Model: Comparing a unloaded scope with a loaded empty scope was returning TRUE
+ [#82](https://github.com/hyperstack-org/hyperstack/issues/82) Hyper Model: Loading a parent scope was not triggering client side scoping of children
+ [#88](https://github.com/hyperstack-org/hyperstack/issues/88) Models were not using pluralize when computing inverse names
+ [#97](https://github.com/hyperstack-org/hyperstack/issues/97) Policies were not guaranteed to load in non-server environments (i.e. rake tasks.)
+ [#98](https://github.com/hyperstack-org/hyperstack/issues/98) Could not use `regulate_class_connection` outside of policy classes.
+ [#101](https://github.com/hyperstack-org/hyperstack/issues/101) Hyper Operation validation errors were not reported to client properly
+ [#105](https://github.com/hyperstack-org/hyperstack/issues/105) Hyper Model records were not persisted in the order created
