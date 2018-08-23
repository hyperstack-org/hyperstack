# Tools

## Hyper-console

Hyper-Console will open a new popup window, that is running an IRB style read-eval loop. The console window will compile what ever ruby code you type, and if it compiles, will send it to your main window for execution. The result (or error message) plus any console output will be displayed in the console window.

## Hyper-spec

With Hyper-Spec you can run isomorphic specs for all your Hyperloop code using RSpec. Everything runs as standard RSpec test specs.

Hyperloop wants to make the server-client divide as transparent to the developer as practical. Given this, it makes sense that the testing should also be done with as little concern for client versus server.

Hyper-spec allows you to directly use tools like FactoryGirl (or Hyperloop Operations) to setup some test data, then run a spec to make sure that a component correctly displays, or modifies that data. You can use Timecop to manipulate time and keep in sync between the server and client. This makes testing easier and more realistic without writing a lot of redundant code.

## Hyper-trace

Method tracing and conditional break points for Opal and Hyperloop debug.

Typically you are going to use this in Capybara or Opal-RSpec examples that you are debugging.

Hyper-trace adds a hypertrace method to all classes that you will use to switch on tracing and break points.

## Opal Hot Reloader

Opal Hot Reloader is for pure programmer joy (not having to reload the page to compile your source) and the Opal Console is incredibly useful to test how Ruby code compiles to JavaScript.

Opal Hot Reloader is going to just dynamically (via a websocket connection) chunks of code in the page almost instaneously.
