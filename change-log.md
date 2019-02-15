# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.4alpha - 2019-02-15
### Security
+ [#117](https://github.com/hyperstack-org/hyperstack/issues/117) Finder methods will return nil instead of raising access violations.

### Added
+ [#120](https://github.com/hyperstack-org/hyperstack/issues/120) Alias `ActiveRecord::Base#new_record?` to `#new?`.
+ [#112](https://github.com/hyperstack-org/hyperstack/issues/112) Add `:init` param to `INPUT`, `SELECT`, and `TEXTAREA` tags.

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
