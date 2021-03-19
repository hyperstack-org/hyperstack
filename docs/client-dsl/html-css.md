# HTML and CSS DSL

### HTML elements

A Hyperstack user-interface is composed of HTML elements, conditional logic and Components.

```ruby
UL do
  5.times { |n| LI { "Number #{n}" }}
end
```
For example

```ruby
DIV(class: 'green-text') { "Let's gets started!" }
```

would create the following HTML:

```markup
<div class="green-text">Let's gets started!</div>
```

And this would render a table:

```ruby
TABLE(class: 'ui celled table') do
  THEAD do
    TR do
      TH { 'One' }
      TH { 'Two' }
      TH { 'Three' }
    end
  end
  TBODY do
    TR do
      TD { 'A' }
      TD(class: 'negative') { 'B' }
      TD { 'C' }
    end
  end
end
```

**[See the predefined tags summary for the complete list of HTML and SVG elements.](predefined-tags.md)**

### Naming Conventions

To distinguish between HTML and SVG tags, builtin components and Application Defined components, the following
naming conventions are followed:

+ `ALLCAPS` denotes a HTML, SVG or builtin React psuedo component such as `FRAGMENT`.
+ `CamelCase` denotes an application defined component class like `TodoList`.



### HTML parameters

You can pass any expected parameter to a HTML or SVG element:

```ruby
A(href: '/') { 'Click me' } # <a href="/">Click me</a>
IMG(src: '/logo.png')  # <img src="/logo.png">
```

Each key-value pair in the parameter block is passed down as an attribute to the tag as you would expect.

### CSS

You can specify the CSS `class` on any HTML element.

```ruby
P(class: 'bright') { }
... or
P(class: :bright) { }
... or
P(class: [:bright, :blue]) { } # class='bright blue'
```

For `style` you need to pass a hash using the [React style conventions](https://reactjs.org/docs/dom-elements.html#style):

```ruby
P(style: { display: item[:some_property] == "some state" ? :block : :none })
```

### Complex Arguments

You can pass multiple hashes which will be merged, and any individual symbols
(or strings) will be treated as `=true`.  For example

```ruby
A(:flag, {href: '/'}, class: 'my_class')
```

will generate

```HTML
<a flag=true href='/' class='myclass'></a>
```

> **[more on passing hashes to methods](notes.html#ruby-hash-params)**
