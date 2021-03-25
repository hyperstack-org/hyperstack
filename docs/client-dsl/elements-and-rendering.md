# Elements and Rendering

document as_node here

### React.create\_element

**Note: You almost never need to directly call `create_element`, the DSL, Rails, and jQuery interfaces take care of this for you.**

A React Element is a component class, a set of parameters, and a group of children. When an element is rendered the parameters and used to initialize a new instance of the component.

`React.create_element` creates a new element. It takes either the component class, or a string \(representing a built in tag such as div, or span\), the parameters \(properties\) to be passed to the element, and optionally a block that will be evaluated to build the enclosed children elements

```ruby
React.create_element("div", prop1: "foo", prop2: 12) { para { "hello" }; para { "goodby" } )
  # when rendered will generates <div prop1="foo" prop2="12"><p>hello</p><p>goodby</p></div>
```

```ruby
# dsl - creates element and pushes it into the rendering buffer
MyComponent(...params...) { ...optional children... }

# dsl - component will NOT be placed in the rendering buffer
MyComponent(...params...) { ... }.as_node

# in a rails controller - renders component as the view
render_component("MyComponent", ...params...)

# in a rails view helper - renders component into the view (like a partial)
react_component("MyComponent", ...)

# from jQuery (Note Element is the Opal jQuery wrapper, not be confused with React::Element)
Element['#container'].render { MyComponent(...params...) { ...optional children... } }
```

### React.is\_valid\_element?

```ruby
is_valid_element?(object)
```

Verifies `object` is a valid react element. Note that `React::Element` wraps the React.js native class, `React.is_valid_element?` returns true for both classes unlike `object.is_a? React::Element`

### React.render

```ruby
React.render(element, container) { puts "element rendered" }
```

Render an `element` into the DOM in the supplied `container` and return a [reference](https://github.com/hyperstack-org/hyperstack/tree/a530e3955296c5bd837c648fd452617e0a67a6ed/docs/more-about-refs.html) to the component.

The container can either be a DOM node or a jQuery selector \(i.e. Element\['\#container'\]\) in which case the first element is the container.

If the element was previously rendered into `container`, this will perform an update on it and only mutate the DOM as necessary to reflect the latest React component.

If the optional block is provided, it will be executed after the component is rendered or updated.

> Note:
>
> `React.render()` controls the contents of the container node you pass in. Any existing DOM elements inside are replaced when first called. Later calls use React’s DOM diffing algorithm for efficient updates.
>
> `React.render()` does not modify the container node \(only modifies the children of the container\). In the future, it may be possible to insert a component to an existing DOM node without overwriting the existing children.

### React.unmount\_component\_at\_node

```ruby
React.unmount_component_at_node(container)
```

Remove a mounted React component from the DOM and clean up its event handlers and state. If no component was mounted in the container, calling this function does nothing. Returns `true` if a component was unmounted and `false` if there was no component to unmount.

### React.render\_to\_string

```ruby
React.render_to_string(element)
```

Render an element to its initial HTML. This is should only be used on the server for prerendering content. React will return a string containing the HTML. You can use this method to generate HTML on the server and send the markup down on the initial request for faster page loads and to allow search engines to crawl your pages for SEO purposes.

If you call `React.render` on a node that already has this server-rendered markup, React will preserve it and only attach event handlers, allowing you to have a very performant first-load experience.

If you are using rails, then the prerendering functions are automatically performed. Otherwise you can use `render_to_string` to build your own prerendering system.

### React.render\_to\_static\_markup

```ruby
React.render_to_static_markup(element)
```

Similar to `render_to_string`, except this doesn't create extra DOM attributes such as `data-react-id`, that React uses internally. This is useful if you want to use React as a simple static page generator, as stripping away the extra attributes can save lots of bytes.

## Prerendering

Prerendering will render your page on the server before sending it to the client. There are some limitations as there is no browser context and no JQuery available. Prerendering is very useful for static sites with complex HTML pages \(like this website\).

**Prerendering is controllable at three levels:**

* In the rails Hyperstack initializer you can say:

  ```ruby
  Hyperstack.configuration do |config|
   config.prerendering = :on # :off by default
  end
  ```

* In a route you can override the config setting by setting a default for Hyperstack\_prerendering:

```ruby
get '/some_page', to: 'Hyperstack#some_page', defaults: {Hyperstack_prerendering: :off} # or :on
```

This allows you to override the prerendering option for specific pages. For example the application may have prererendering off by default \(via the config setting\) but you can still turn it on for a specific page.

* You can override the route, and config setting using the Hyperstack-prerendering query param:

```markup
http://localhost:3000/my_hyper_app/some_page?Hyperstack-prerendering=off
```

This is useful for development and testing.

> Note: in the route you say Hyperstack\_prererendering but in the query string its Hyperstack-prerendering \(underscore vs. dash\). This is because of rails security protection when using defaults.

## DSL Gotchas

There are few gotchas with the DSL you should be aware of:

React has implemented a browser-independent events and DOM system for performance and cross-browser compatibility reasons. We took the opportunity to clean up a few rough edges in browser DOM implementations.

* All DOM properties and attributes \(including event handlers\) should be snake\_cased to be consistent with standard Ruby style. We intentionally break with the spec here since the spec is inconsistent. **However**, `data-*` and `aria-*` attributes [conform to the specs](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes#data-*) and should be lower-cased only.
* The `style` attribute accepts a Hash with camelCased properties rather than a CSS string. This  is more efficient, and prevents XSS security holes.
* All event objects conform to the W3C spec, and all events \(including submit\) bubble correctly per the W3C spec. See [Event System](hyper-component.md#event-handling-and-synthetic-events) for more details.
* The `onChange` event \(`on(:change)`\) behaves as you would expect it to: whenever a form field is changed this event is fired rather than inconsistently on blur. We intentionally break from existing browser behavior because `onChange` is a misnomer for its behavior and React relies on this event to react to user input in real time.
* Form input attributes such as `value` and `checked`, as well as `textarea`.

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
