# Hyperstack 1.0

## Top-level project goals

+ One language for all code (which is Ruby for now)
+ Avoiding repetitive and boilerplate code.
+ Use convention over configuration where possible.
+ Class definitions that are internally consistent, and stable over time.
+ Class definitions that act like existing well known structures.
+ As friction free as possible configuration and development tool chain.
+ Good documentation, and a helpful community, both for users, and contributors.
+ A professional, well structured code base, complete test coverage, and automatic continuous integration.
+ Implementation should be as efficient both in speed and space as practical given the above.

## Roadmap

### Hyperloop (!!) version 0.99 - final Hyperloop version

#### mission:  release the functionality of current hyperloop edge branch

+ ~~move current gem set to one repo under hyperstack (done - tx Barry)~~
+ ~~get specs to pass with current names (done - tx Mitch and Johan)~~
+ ~~release under old hyperloop gem names version 0.99~~
+ ~~publish to hyperloop-legacy branch *(not master)* with tag 0.99~~
+ update old website

------

### Hyperstack version 1.0.0.alpha1

#### mission: move to new naming conventions

+ rename modules and classes per new naming conventions
+ include a deprecation module
+ document upgrade path
+ release under new gem names with version 0.1
+ tag as master version  0.1
+ release new website with updated docs
+ clearly document (in hyperloop repo and old website) that we have moved

### version 0.2

#### mission:  Integrate OWL (Opal-Webpack-Loader)

+ document install and usage instructions for OWL, and lazy loading
+ release and tag as master version 0.2

### version 0.3

#### mission: make independent of Rails

+ details TBD, may include restructure of gems as client and server adapters
+ document upgrade instructions
+ release and tag as master version 0.3

### version 0.4 ... as needed until all APIs, DSLs, configuration mechanisms, and semantics are stable

------

### version 1.0.rc1

#### mission: first attempt at the 1.0 release

### version 1.0.rc2 … etc

#### mission: bug fixes until ready to release

------

### version 1.0
