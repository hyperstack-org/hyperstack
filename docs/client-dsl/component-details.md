### Children

Components often have child components.  If you consider HTML tags like `DIV`, `UL`, and `TABLE`
you will see you are already familiar with this concept:

```ruby
DIV(id: 1) do
  SPAN(class: :span_1)  { 'hi' }
  SPAN(class: :span_2) { 'there' }
end
```
Here we have a `DIV` that receives one param, an id equal to 1 and has two child *elements* - the two spans.

The `SPAN`s each have one param (its css class) and has one child *element* - a string to render.

Hopefully at this point the DSL is intuitive to read, and you can see that this will generate the following HTML:
```HTML
<div id=1>
  <span class='first_span'>hi</span>
  <span class='second_span'>there</span>
</div>
```

### Dynamic Children

Children do not have to be statically generated.  Let's sort a string of text
into individual word counts and display it in a list:

```ruby
# assume text is a string of text
UL do
  word_count(text).each_with_index do |word, count|
    LI { "#{count} - #{word}" }
  end
end
```
In this case you can see that we don't determine the actual number or contents of the `LI` children until runtime.

>**[The `word_count` method...](notes.md#word-count-method)**

>Dynamically generating components creates a new concept called ownership.  **[More here...](notes.md#ownership)**

### Keys

In the above example what would happen if the contents of `text` were dynamically changing? For
example if it was associated with a text box that the user was typing into, and we updated `text`
whenever a word was entered.

In this case as the user typed new words, the `word_count` would be updated and the list would change.
However actually only the contents of one of the list items (`LI` blocks) would actually change, and
perhaps the sort order.  We don't need to redraw the whole list, just the one list item that changed,
and then perhaps shuffle two of the items.  This is going to be much faster than redrawing the whole
list.

Like React, Hyperstack provides a special `key` param that can identify child elements so that the
rendering engine will know that while the content and order may change on some children, it can easily
identify the ones that are the same:

```ruby
    LI(key: word) { "#{count} - #{word}"}
```

You don't have to stress out too much about keys, its easy to add them later.  Just keep the concept in
mind when you are generating long lists, tables, and divs with many children.

> **[More on how Hyperstack generates keys...](notes.md#generating-keys)**

### Rendering Children

Application defined components can also receive and render children.
A component's `children` method returns an enumerable that is used to access the *unrendered* children of a component.  The children can then be rendered
using the `render` method which will merge any additional parameters and
render the child.

```ruby
class Indenter < HyperComponent
  render(DIV) do
    IndentLine(by: 10) do # see IndentLine below
      DIV {"Line 1"}
      DIV {"Line 2"}
      DIV {"Line 3"}
    end
  end
end

class IndentLine < HyperComponent
  param by: 20, type: Integer

  render(DIV) do
    children.each_with_index do |child, i|
      child.render(style: {"margin-left" => by*i})
    end
  end
end
```

### Rendering Multiple Values and the FRAGMENT component

A render block may generate multiple values.  React assumes when a Component generates multiple items, the item order and quantity may
change over time and so will give a warning unless each element has a key:

```ruby
class ListItems < HyperComponent
  render do
    # without the keys you would get a warning
    LI(key: 1) { 'item 1' }
    LI(key: 2) { 'item 2' }
    LI(key: 3) { 'item 3' }
  end
end

# somewhere else:
   UL do
     ListItems()
   end
```

If you are sure that the order and number of elements will not change over time you may wrap the items in the `FRAGMENT` pseudo component:

```ruby
class ListItems < HyperComponent
  render(FRAGMENT) do
    LI { 'item 1' }
    LI { 'item 2' }
    LI { 'item 3' }
  end
end
```
