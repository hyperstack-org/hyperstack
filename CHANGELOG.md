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

## [0.8.9] - Unreleased

### Fixed

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
