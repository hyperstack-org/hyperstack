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
