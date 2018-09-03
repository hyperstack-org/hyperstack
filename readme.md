# Hyperstack 1.0 

## Goals of this release

+ First Hyperstack release based on last Hyperloop
+ Change class names from Hyperloop to Hyperstack convention
+ All gems building from one repo with an automated test, build, deploy process
+ 10x speed improvement in hyper-spec
+ Opal-webpack-loader based build process
+ New webesite and updated docs and tutorials
+ Use rails templates for installation and setup
+ Depreciation of changes and documented upgrade path

## Roadmap

### Hyperloop (!!) version 0.99

#### mission:  release the functionality of current hyperloop edge branch

+ move current gem set to one repo under hyperstack (done - tx Barry)
+ get specs to pass with current names
+ release under old hyperloop gem names version 0.99
+ publish to hyperloop-legacy branch *(not master)* with tag 0.99

------

### Hyperstack version 0.1

#### mission: move to new naming conventions

+ rename modules and classes per new naming conventions
+ include a deprecation module
+ document upgrade path
+ release under new gem names with version 0.1
+ tag as master version  0.1

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
