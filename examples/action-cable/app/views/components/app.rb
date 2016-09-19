# app/views/components/app.rb
class App < React::Component::Base
  # change Article to whatever your model name is
  render do
    div do
      "Count of MyModel: #{Article.all.count}".span
      #puts "last article: #{Article.all.last}"
      puts "article count: #{Article.all.count}"
      " last id = #{Article.all.last.id}".span unless Article.all.count == 0
      button { "add another" }.on(:click) { Article.new(title: "created at #{Time.now}").save }
    end
  end
end
