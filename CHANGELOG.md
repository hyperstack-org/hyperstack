# Change Log

All notable changes to this project will be documented in this file starting with v0.8.6.
This project *tries* to adhere to [Semantic Versioning](http://semver.org/), even before v1.0.

Changes are grouped as follows:
- **Added** for new features.
- **Changed** for changes in existing functionality.
- **Deprecated** for once-stable features to be removed in upcoming releases.
- **Removed** for deprecated features removed in this release.
- **Fixed** for any bug fixes.
- **Security** to invite users to upgrade in case of vulnerabilities.

<!--
Whitespace conventions:
- 4 spaces before ## titles
- 2 spaces before ### titles
- 1 spaces before normal text
 -->

## [0.11.0] - Unreleased

### Changed

- The whole opal-activesuppport is not loaded by default now. If your code rely on any of the module which is not required by hyper-react, you need to require it yourself. (#135)

### Deprecated

- `React.is_valid_element` is deprecated in favor of `React.is_valid_element?`.
- `expect(component).to render('<div />')` is now deprecated in favor of `expect(component).to render_static_html('<div />')`, which is much clearer.

### Fixed

- Arity checking failed for `_react_param_conversion` & `React::Element#initialize` (#167)


## [0.10.0] - 2016-10-30

### Changed

- This gem is now renamed to `hyper-react`, see [UPGRADING](UPGRADING.md) for details.

### Fixed

- ReactJS functional stateless component could not be imported from `NativeLibrary`. Note that functional component is only supported in React v14+.  (#162)
- Prerender log got accumulated between reqeusts. (#176)

## [0.9.0] - 2016-10-19

### Added

- `react/react-source` is the suggested way to include ReactJS sources now. Simply require `react/react-source` immediately before the `require "reactrb"` in your Opal code will make it work.

### Deprecated

- `react-latest` & `react-v1x` is deprecated. Use `react/react-source` instead.

### Removed

- `opal-browser` is removed from runtime dependency. (#133)  You will have to add `gem 'opal-browser'` to your gemfile (recommended) or remove all references to opal-browser from your manifest files.

### Fixed

- `$window#on` in `opal-jquery` is broken. (#166)
- `Element#render` trigger unnecessary re-mounts when called multiple times. (#170)
- Gets rid of react warnings about updating state during render (#155)
- Multiple HAML classes (i.e. div.foo.bar) was not working (regression introduced in 0.8.8)
- Don't send nil (null) to form components as the value string (#157)
- Process `params` (props) correctly when using `Element#on` or `Element#render` (#158)
- Deprecate shallow param compare (#156)


## [0.8.8] - 2016-07-13

### Added

- More helpful error messages on render failures (#152)
- `Element#on('<my_event_name>')` subscribes to `my_event_name` (#153)

### Changed

- `Element#on(:event)` subscribes to `on_event` for reactrb components and `onEvent` for native components. (#153)

### Deprecated

- `Element#on(:event)` subscription to `_onEvent` is deprecated. Once you have changed params named `_on...` to `on_...` you can `require 'reactrb/new-event-name-convention.rb'` to avoid spurious react warning messages. (#153)


### Fixed

- The `Element['#container'].render...` method generates a spurious react error (#154)




## [0.8.7] - 2016-07-08


### Fixed

- Opal 0.10.x compatibility


## [0.8.6] - 2016-06-30


### Fixed

- Method missing within a component was being reported as `incorrect const name` (#151)
