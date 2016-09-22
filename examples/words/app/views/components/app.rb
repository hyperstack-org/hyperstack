# app/views/components/app.rb
class App < React::Component::Base

  define_state :loading

  def add_new_word
    state.loading! true
    HTTP.get("http://randomword.setgetgo.com/get.php", dataType: :jsonp) do |response|
      Word.create(text: response.json[:Word]).then { state.loading! false }
    end
  end

  def display_word(word)
    LI do
      SPAN(style: {marginRight: 10}) { word.text }
      BUTTON { "delete!" }.on(:click) { word.destroy }
    end
  end

  render(DIV) do
    SPAN(style: {marginRight: 10}) { "Count of Words: #{Word.sorted.count}" }
    if state.loading
      SPAN { "loading..." }
    else
      BUTTON { "add another" }.on(:click) { add_new_word }
    end
    UL do
      Word.sorted.each { |word| display_word word }
    end
  end
end
