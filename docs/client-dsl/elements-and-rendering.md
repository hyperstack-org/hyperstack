This section documents some technical details of the interface between React and Hyperstack as well as some useful low level methods.

## The `Hyperstack::Component` Module

The `Hyperstack::Component` module can be included in any Ruby class, and will add the methods that interface between that class and React.  Specifically it will

+ Define the class level methods such as param, render and the other lifecycle methods,
+ Provide the render DSL which has the same role as JSX but uses Ruby methods,
+ Provide a suitable Javascript class constructor that so that React will recognize the instances of the Component as React Elements

The only major difference between the systems is that JSX compiles directly to React API calls (such as `createElement`) while Hyperstack executes an expression like `MyBigComponent(class: :red, some_param: :foo)` and directly calls `createElement` passing the `MyBigComponent` react class, and translating it as needed from Ruby to JS conventions.

As each React element is generated it is stored by Hyperstack in a *rendering buffer*, and when the component finishes the rendering block, the buffer is returned as the result of the components render callback.  If the expression has a child block (like `DIV { 'hello' }`) the block is passed to the `createElement` as a the child function the same
as JSX would do.

When an expression like this is evaluated (**[see the full example in the section on params...](../params#named-child-components-as-params)**)
```ruby
  Reveal(content: DIV { 'I came from the App' })
```
we need to *remove* the generated `DIV` element *out* of the rendering buffer before passing it to `Reveal`.  This is done automatically by applying the `~` (remove) operator to the
`DIV` as it is passed on.

In general you will never have to manually use the remove (`~`) operator, as React's declarative nature makes storing elements for later use not as necessary as in more
procedural frameworks.

#### Creating Elements Programmatically

Component classes (including tags like `DIV`) respond to two methods for programmatically creating elements:

```Ruby
# component_class evaluates to some Component Class
component_class.create_element(<params hash>) { <optional block> }
component_class.insert_element(<params hash>) { <optional block> }
```
both methods return the generated element, the second also inserts into the current rendering buffer.

#### Rendering to the DOM

Sooner or later it has to end up in the DOM.  If you are using Rails then Hyperstack includes several
methods to *mount* your components onto the display.  See the Rails installation section for details.

Otherwise if using jQuery then you can use the `render` method:
```Ruby
Document.ready? do # ready runs when document is loaded
  jQ['div#mount_point'].render(App)
end
```

or do it completely yourself with the low level ReactAPI

```Ruby
# somewhere in a JS onload page handler:
Hyperstack::Component::ReactAPI.render(App.create_element, `getElementById('mount_point')`)
```

#### React.unmount\_component\_at\_node

To remove a element that has been mounted:

```ruby
Hyperstack::Component::ReactAPI.unmount_component_at_node(dom_container)
```

This removes a mounted component from the DOM and cleans up its event handlers and state. If no component was mounted in the container, calling this function does nothing. Returns `true` if a component was unmounted and `false` if there was no component to unmount.

### React.render\_to\_string

```ruby
Hyperstack::Component::ReactAPI.render_to_string(element)
```

Render an element to its initial HTML. This is should only be used on the server for prerendering content. React will return a string containing the HTML. You can use this method to generate HTML on the server and send the markup down on the initial request for faster page loads and to allow search engines to crawl your pages for SEO purposes.

If you call `ReactAPI.render` on a node that already has this server-rendered markup, React will preserve it and only attach event handlers, allowing you to have a very performant first-load experience.

If you are using rails, then the prerendering functions are automatically performed. Otherwise you can use `render_to_string` to build your own prerendering system.

### React.render\_to\_static\_markup

```ruby
React.render_to_static_markup(element)
```

Similar to `render_to_string`, except this doesn't create extra DOM attributes such as `data-react-id`, that React uses internally. This is useful if you want to use React as a simple static page generator, as stripping away the extra attributes can save lots of bytes.

### HTML Entities

If you want to display an HTML entity within dynamic content, you will run into double escaping issues as React.js escapes all the strings you are displaying in order to prevent a wide range of XSS attacks by default.

```ruby
DIV {'First &middot; Second' }
  # Bad: It displays "First &middot; Second"
```

To workaround this you have to insert raw HTML.

```ruby
DIV(dangerously_set_inner_HTML: { __html: "First &middot; Second"})
```

### Custom HTML Attributes

If you pass properties to native HTML elements that do not exist in the HTML specification, React will not render them. If you want to use a custom attribute, you should prefix it with `data-`.

```ruby
DIV("data-custom-attribute" => "foo")
```

[Web Accessibility](http://www.w3.org/WAI/intro/aria) attributes starting with `aria-` will be rendered properly.

```ruby
DIV("aria-hidden" => true)
```
