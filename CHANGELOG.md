# Change Log

All notable changes to this project will be documented in this file starting with v0.8.4.
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

## [0.5.3] - 2017-01-03


### Added

- Fixed problem with synchronizing multiple requests to same record within one render cycle (#20)
- Add *finder* methods.  I.e. server side methods that return a single record using a custom query. (#12)
- Allow `save` even if records are loading (#10)
- `ReactiveRecord.Load` will automatically apply `.itself` to the final value of the load block (#9)


### Fixed

- Can't create AR records from within Rake Tasks. (#20)
