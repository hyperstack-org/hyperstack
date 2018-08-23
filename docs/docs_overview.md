# Welcome to Hyperstack!

**Hyperstack 1.0 and Hyperstack 2.0 are work-in-progress. Please consider everything in this repo as ALPHA.**

Hyperloop (version 0.9) is stable, and the existing website remains in place. If you are looking for a production ready project, then please stay there until this is released. http://ruby-hyperloop.org

In this project, there are two Hyperstack implementations (HS1 and HS2). The goals of each are detailed below.

This website loads all content dynamically from the HS1 and HS2 projects. You can switch the document base using the link in topbar.  

## Hyperstack 2.0 (HS2)

### Release goals:

+ Backend independent - no dependency on Rails, ReactRails and OpalRails
+ Supported backends: Rails & Roda (others to be community added)
+ Webpack based build and hot-reloading process (no Sprockets)
+ Faster and simplified Isomorphic Models
  + Redis for pub/sub
  + ORM agnostic (tested with ActiveRecord SQL and Neo4j.rb)
  + No need for data broadcast Policy
+ Updated Operation DSL (business logic and bidirectional client/server execution)
+ HyperGate for authorisation and authentication on the client and server
+ Faster rspec framework plus automated build and deploy process

### Change management needed:

+ HyperResource is a rewrite (and replacement of) HyperMesh. There should be minimal client-side DSL difference, but we need to capture any conceptual or DSL changes / document features that will be missing
+ HyperOperation upgraded DSL will require docs changes, bring in step DSL
+ Policy is deprecated so we need to ensure that no functionality is lost
+ Setup and installation docs per supported framework
+ General gem naming and versioning, dependency restrictions / make sure the new stack does not pull in new stuff
+ Two documents must be maintained (Barrie will maintain these):
  + Upgrading from HL/HS1 to HS2
  + HS2 DSL/functional change log (detailing each functional or DSL change, the implication and hopefully a link to the commit so that it can be understood)

### Out of scope / constraints:

+ Component, Model, Store and Operation DSL changes should be kept to a minimum and where there are changes, deprecation must be considered.
The 2.0 release cannot be a moving target. Our goals is to replace 1.0 in the quickest time possible then evolve 2.0 part by part (not be in this situation again)
+ It is understood that HS2 will be better and faster and offer more functionality than HS1. It is completely understood that HS1 DSL != HS2 DSL but where there is a difference, there needs to be comprehensive change management
+ If the testing framework is changed (because it is too slow to run), we MUST ensure that the existing tests work with the new framework. There are thousands of tests which have been written over many years, the value of these will not be let go. If we change the framework then it is our responsibility to ensure the existing tests work properly with the new framework. This pertains to all HyperReact, HyperRouter, and HyperStore tests.
  + Where there is functional or DSL change, then we must change the corresponding tests so that they remain valid.
