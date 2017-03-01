TODO: not sure where this should go?

## Random Words example

This is the example app used by the quick start guides, and if you want to dive deeper this is the place to be.

If you have not already done so, follow any one of the quick start guides to set up the basic system.  Make sure to follow the steps in the last section and add a `Word` model, a `App` component, and a controller and route.

### The initial component:

Your initial component should look like this:

```ruby
# app/views/components/app.rb
class App < Hyperloop::Component

  def add_new_word
    # for fun we will use setgetgo.com to get random words!
    HTTP.get("http://randomword.setgetgo.com/get.php", dataType: :jsonp) do |response|
      Word.new(text: response.json[:Word]).save
    end
  end

  render(DIV) do
    SPAN { "Count of Words: #{Word.count}" }
    BUTTON { "add another" }.on(:click) { add_new_word }
    UL do
      Word.each { |word| LI { word.text } }
    end
  end
end
```

Before going further lets understand exactly what is going on here.

1) Our controller has a method named `app`, so by convention Reactrb will look for a
component class named `App`, which it finds and *mounts* where ever the the *layout* yields to the view.  

Take a second to look at your `application.html.erb` and find the `<%= yield %>`.  That is the normal rails way of
indicating where the view requested by the controller (in the case our component) should be rendered.

2) The component is rendered on the server like any other view.  The `render` callback defines exactly what to render.  


```ruby
# app/views/components/app.rb
class App < React::Component::Base

  def add_new_word
    # for fun we will use setgetgo.com to get random words!
    word = Word.new(text: '')
    Word << word # force our local list to update before the save
    HTTP.get("http://randomword.setgetgo.com/get.php", dataType: :jsonp) do |response|
      word.text = response.json[:Word]
      word.save
    end
  end

  render(DIV) do
    SPAN { "Count of Words: #{Word.count}" }
    BUTTON { "add another" }.on(:click) { add_new_word }
    UL do
      Word.sort.each { |word| LI { word.text.empty? ? 'loading...' : word.text } }
    end
  end
end
```
