class Test

  include React::Component

  def render
    user = User.find_by_email("mitch@catprint.com")
    div do
      "#{Time.now.to_s} #{user.first_name}".br
      "zip: #{user.address.zip}".br
      "todos: #{user.todo_items.collect { |todo| todo.title }.join(", ")}".br
      "first todo in find_string(mitch) scope: #{user.todo_items.find_string("mitch").first.title}".br
      "a comment was made by: #{user.todo_items.first.commenters.first.email}".br
      "some expensive math: #{user.expensive_math(13)}".br
      "and a server side method: #{user.detailed_name}".br.tap { user.first_name = "joe"; user.detailed_name! }
    end
  end

end
