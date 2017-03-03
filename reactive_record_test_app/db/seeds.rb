require './app/models/public/comment'
require './app/models/public/todo_item'
require './app/models/public/address'
require './app/models/public/user'


users = [
  ["Mitch", "VanDuyn", "mitch@catprint.com"],
  ["Todd", "Russell", "todd@catprint.com"],
  ["Adam", "George", "adamg@catprint.com"],
  ["Test1", "Test1", "test1@catprint.com"]
]

users.each do |first_name, last_name, email|
  User.create({
    first_name: first_name, last_name: last_name, email: email,
    address_street: "4348 Culver Road", address_city: "Rochester", address_state: "NY", address_zip: "14617"
    }
    #without_protection: true
  )
end

todo_items = [
  {
    title: "a todo for mitch",
    description: "mitch has a big fat todo to do!",
    user: User.find_by_email("mitch@catprint.com"),
    comments: [{user: User.find_by_email("adamg@catprint.com"), comment: "get it done mitch"}]
  },
  {
    title: "another todo for mitch",
    description: "mitch has too many todos",
    user: User.find_by_email("mitch@catprint.com")
  },
  {
    title: "do it again Todd",
    description: "Todd please do that great thing you did again",
    user: User.find_by_email("todd@catprint.com")
  },
  {
    title: "no user todo",
    description: "the description"
  },
  {
    title: "test 1 todo 1", description: "test 1 todo 1", user: User.find_by_email("test1@catprint.com"),
    comments: [
      {user: User.find_by_email("mitch@catprint.com"), comment: "test 1 todo 1 comment 1"},
      {user: User.find_by_email("mitch@catprint.com"), comment: "test 1 todo 1 comment 2"}
    ]
  },
  {
    title: "test 1 todo 2", description: "test 1 todo 2", user: User.find_by_email("test1@catprint.com"),
    comments: [
      {user: User.find_by_email("mitch@catprint.com"), comment: "test 1 todo 2 comment 1"},
      {user: User.find_by_email("mitch@catprint.com"), comment: "test 1 todo 2 comment 2"}
    ]
  }
]

todo_items.each do |attributes|
  comments = attributes.delete(:comments) || []
  todo = TodoItem.create(attributes) #, without_protection: true)
  comments.each do |attributes|
    Comment.create(attributes.merge(todo_item: todo))
  end
end
