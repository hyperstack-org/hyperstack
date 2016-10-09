class Comment < ActiveRecord::Base
  # see spec/examples folder for typically setup
  belongs_to :author, class_name: "User"
  belongs_to :todo
end
