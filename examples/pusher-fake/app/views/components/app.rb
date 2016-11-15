# app/views/components/app.rb
class App < React::Component::Base

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
