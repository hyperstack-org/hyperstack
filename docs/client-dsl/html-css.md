# HTML and CSS DSL

## HTML DSL

### HTML elements

A Hyperstack user-interface is composed of HTML elements, conditional logic and Components.

```ruby
UL do
  5.times { |n| LI { "Number #{n}" }}
end
```

> **Notice that the HTML elements \(BUTTON, DIV, etc.\) are in CAPS**. We know this is bending the standard Ruby style rules, but we think it reads better this way.

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

The following HTML and SVG elements are available:

<details>
<summary>HTML Tags</summary><div><pre><code>
A ABBR ADDRESS AREA ARTICLE ASIDE AUDIO  
B BASE BDI BDO BIG BLOCKQUOTE BODY BR BUTTON  
CANVAS CAPTION CITE CODE COL COLGROUP  
DATA DATALIST DD DEL DETAILS DFN DIALOG DIV DL DT  
EM EMBED  
FIELDSET FIGCAPTION FIGURE FOOTER FORM  
H1 H2 H3 H4 H5 H6 HEAD HEADER HR HTML  
I IFRAME IMG INPUT INS  
KBD KEYGEN  
LABEL LEGEND LI LINK  
MAIN MAP MARK MENU MENUITEM META METER  
NAV NOSCRIPT  
OBJECT OL OPTGROUP OPTION OUTPUT  
P PARAM PICTURE PRE PROGRESS  
Q  
RP RT RUBY  
S SAMP SCRIPT SECTION SELECT SMALL SOURCE SPAN STRONG STYLE SUB SUMMARY SUP  
TABLE TBODY TD TEXTAREA TFOOT TH THEAD TIME TITLE TR TRACK  
U UL  
VAR VIDEO  
WBR
</code></pre></div>
</details>


<details>
<summary>SVG Tags</summary><div><pre><code>
CIRCLE CLIPPATH  
DEFS  
ELLIPSE  
G  
LINE LINEARGRADIENT  
MASK  
PATH PATTERN POLYGON POLYLINE  
RADIALGRADIENT RECT  
STOP  
SVG  
TEXT TSPAN
</code></pre></div>
</details>


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
PARA(style: { display: item[:some_property] == "some state" ? :block : :none })
```

### Complex Arguments

You can pass multiple hashes which will be merged, and any individual symbols
(or strings) will be treated as `=true`.  For example

```ruby
A(:flag, {href: '/'}, {class: 'my_class'})
```

will generate

```HTML
<a flag=true href='/' class='myclass'></a>
```
