# app/views/components/app.rb
class Words < React::Component::Base

  param :words

  render(UL) do
    params.words.each { |word| LI { word.text } }
  end

  hypertrace instrument: :all

end


class App < React::Component::Base

  define_state :waiting_for_word

  def add_new_word
    # for fun we will use setgetgo.com to get random words!
    state.waiting_for_word! true
    HTTP.get("http://randomword.setgetgo.com/get.php", dataType: :jsonp) do |response|
      Word.new(text: response.json[:Word]).save { state.waiting_for_word! false }
    end
  end

  render(DIV) do
    SPAN { "Count of Words: #{Word.count}" }
    BUTTON { "add another" }.on(:click) { add_new_word } unless state.waiting_for_word
    #Words(words: Word.all)
    UL do
      Word.each { |word| LI { word.text } }
    end
  end

  hypertrace instrument: :render
end

#ReactiveRecord::Collection.hypertrace instrument: :instance_variable_set
#React::State.hypertrace :class, instrument: :all
