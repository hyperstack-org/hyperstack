# Hyperstack ALPHA

## Release goals:

+ Backend independent - no dependency on Rails, ReactRails and OpalRails
+ Supported backends: Rails & Roda (others to be community added)
+ Webpack based build and hot-reloading process (no Sprockets)
+ Faster and simplified Isomorphic Models
  + Redis for pub/sub
  + ORM agnostic (tested with ActiveRecord SQL and Neo4j.rb)
  + No need for data broadcast Policy
+ Updated Operation DSL (business logic and bidirectional client/server execution)
+ HyperPolicy for authorisation and authentication on the client and server
+ Faster rspec framework plus automated build and deploy process

## Change management needed:

+ HyperResource is a rewrite (and replacement of) HyperMesh. There should be minimal client-side DSL difference, but we need to capture any conceptual or DSL changes / document features that will be missing
+ HyperOperation upgraded DSL will require docs changes, bring in step DSL
+ Policy is deprecated so we need to ensure that no functionality is lost
+ Setup and installation docs per supported framework
+ General gem naming and versioning, dependency restrictions / make sure the new stack does not pull in new stuff
+ Two documents must be maintained (Barrie will maintain these):
  + Hyperstack DSL/functional change log (detailing each functional or DSL change, the implication and hopefully a link to the commit so that it can be understood)

## Out of scope / constraints:

+ Component, Model, Store and Operation DSL changes should be kept to a minimum and where there are changes, deprecation must be considered.
The 2.0 release cannot be a moving target. Our goals is to replace 1.0 in the quickest time possible then evolve 2.0 part by part (not be in this situation again)
+ Hyperstack will be better and faster and offer more functionality than Hyperloop. It is completely understood that the Hyperstack DSL != Hyperloop DSL but where there is a difference, there needs to be comprehensive change management
+ If the testing framework is changed (because it is too slow to run), we MUST ensure that the existing tests work with the new framework. There are thousands of tests which have been written over many years, the value of these will not be let go. If we change the framework then it is our responsibility to ensure the existing tests work properly with the new framework. This pertains to all HyperReact, HyperRouter, and HyperStore tests.
  + Where there is functional or DSL change, then we must change the corresponding tests so that they remain valid.
