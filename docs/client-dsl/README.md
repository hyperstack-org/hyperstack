# Client DSL

## HTML DSL and Hyperstack Component classes

A key design goal of the DSL \(Domain Specific Language\) is to make it work seamlessly with the rest of Ruby and easy to work with HTML elements and Components. Additionally, the DSL provides an abstraction layer between your code and the underlying \(fast moving\) technology stack. Hyperstack always uses the very latest versions of React and React Router yet our DSL does not change often. We believe that a stable DSL abstraction is an advantage.

This documentation will cover the following core concepts:

+ [HTML & CSS DSL](html-css.md) which provided Ruby implementations of all of the HTML and CSS elements
+ [Component DSL](components.md) is a Ruby DSL which wraps ReactJS Components
+ [Lifecycle Methods](lifecycle-methods.md) are methods which are invoked before, during and after rendering
+ [State](state.md) governs all rendering in ReactJS
+ [Event Handlers](event-handlers.md) allow any HTML element or Component can respond to an event
+ [JavaScript Components](javascript-components.md) for the full universe of JS libraries in your Ruby code
+ [Client-side Routing](hyper-router.md) a Ruby DSL which wraps ReactRouter
+ [Stores](hyper-store.md) for application level state and Component communication
+ [Elements and Rendering](elements-and-rendering.md) which are seldom used but useful to know
+ [Further Reading](further-reading.md) on React and Opal

